import { dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

export default {
  '*': (filenames) => `${__dirname}/node_modules/.bin/secretlint --format checkstyle --secretlintrc ${__dirname}/.secretlintrc.json ${filenames.join(' ')} | reviewdog -fail-on-error -f checkstyle -diff "git diff --cached" -reporter local`,
  '.github/workflows/*.{yml,yaml}': (filenames) => `actionlint ${filenames.join(' ')}`
}
