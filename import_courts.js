const fs = require('fs');
const cheerio = require('cheerio');
const glob = require('glob');
const { Client } = require('pg');

const SOURCE_SITE = 'エース市川';

function parseDate(raw) {
	  return `${raw.slice(0, 4)}-${raw.slice(4, 6)}-${raw.slice(6, 8)}`;
}

function parseTimeKeyToStart(timeKey) {
	  const s = String(timeKey).padStart(6, '0');
	  const hh = Number(s.slice(0, 2));
	  const mm = Number(s.slice(2, 4));
	  return { hh, mm };
}

function formatTime(hh, mm) {
	  return `${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}:00`;
}

function addMinutes(hh, mm, add) {
	  const total = hh * 60 + mm + add;
	  const endH = Math.floor(total / 60);
	  const endM = total % 60;
	  return { hh: endH, mm: endM };
}

function parseHtml(filePath) {
	  const html = fs.readFileSync(filePath, 'utf8');
	  const $ = cheerio.load(html);

	  const playDateRaw = $('#day option[selected="selected"]').attr('value');
	  const facilityName = $('#sisetuGrpCD option[selected="selected"]').text().trim();
	  const courtName = $('#sisetuCD option[selected="selected"]').text().trim();

	  if (!playDateRaw || !facilityName || !courtName) {
		      throw new Error(`必要な値が取れませんでした: ${filePath}`);
		    }

	  const playDate = parseDate(playDateRaw);
	  const rows = [];

	  $('.ui-grid-a-37').each((_, block) => {
		      $(block).find('button[data-pkey]').each((__, btn) => {
			            const timeKey = $(btn).attr('data-pkey');
			            const className = $(btn).attr('class') || '';

			            const { hh, mm } = parseTimeKeyToStart(timeKey);
			            const end = addMinutes(hh, mm, 15);

			            rows.push({
					            source_site: SOURCE_SITE,
					            facility_name: facilityName,
					            court_name: courtName,
					            play_date: playDate,
					            start_time: formatTime(hh, mm),
					            end_time: formatTime(end.hh, end.mm),
					            status: className.includes('List_Button_Disable') ? 'unavailable' : 'available',
					          });
			          });
		    });

	  return rows;
}

async function main() {
	  const client = new Client({
		      host: process.env.PGHOST || 'localhost',
		      port: Number(process.env.PGPORT || 5432),
		      database: process.env.PGDATABASE,
		      user: process.env.PGUSER,
		      password: process.env.PGPASSWORD,
		    });

	  if (!process.env.PGDATABASE || !process.env.PGUSER || !process.env.PGPASSWORD) {
		      throw new Error('PGDATABASE / PGUSER / PGPASSWORD を環境変数で指定してください');
		    }

	  await client.connect();

	  const files = glob.sync('*_court_*.html').sort();
	  let total = 0;

	  for (const file of files) {
		      const rows = parseHtml(file);

		      for (const row of rows) {
			            await client.query(
					            `
					            INSERT INTO public.court_availability (
							              source_site,
							              facility_name,
							              court_name,
							              play_date,
							              start_time,
							              end_time,
							              status
							            )
					            VALUES ($1, $2, $3, $4, $5, $6, $7)
					            ON CONFLICT (
							              source_site,
							              facility_name,
							              court_name,
							              play_date,
							              start_time,
							              end_time
							            )
					            DO UPDATE SET
					              status = EXCLUDED.status,
					              fetched_at = now()
					            `,
					            [
							              row.source_site,
							              row.facility_name,
							              row.court_name,
							              row.play_date,
							              row.start_time,
							              row.end_time,
							              row.status,
							            ]
					          );
			            total++;
			          }

		      console.log(`imported: ${file} (${rows.length} rows)`);
		    }

	  console.log(`done: ${total} rows processed`);
	  await client.end();
}

main().catch((err) => {
	  console.error(err);
	  process.exit(1);
});
