import { dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

export default {
  '*': `${__dirname}/scripts/lint-secretlint.sh`,
  '.github/workflows/*.{yml,yaml}': `${__dirname}/scripts/lint-actionlint.sh`,
  '*.@(js|ts|tsx)': `${__dirname}/scripts/lint-consolelog.sh`,
}
