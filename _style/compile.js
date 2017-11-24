let sass = require('node-sass');
let fs   = require('fs');

if ((3 > process.argv.length) || (null == process.argv[2].match('.*css'))) {
  console.error('Please select the css output file');
  process.exit(1);
}

let logOnFailure = (err, next) => {if(err) console.error(err); else if(next) next();}
let save         = (err, result) => logOnFailure(err, () => fs.writeFile(process.argv[2], result.css, (err, _) => logOnFailure(err)));
sass.render({file: 'main.scss'}, save);
