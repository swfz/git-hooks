import { dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

export default {
  '*': (filenames) => `${__dirname}/node_modules/.bin/secretlint --secretlintrc ${__dirname}/.secretlintrc.json ${filenames.join(' ')}`,
  '.github/workflows/*.{yml,yaml}': (filenames) => `actionlint ${filenames.join(' ')}`
}
