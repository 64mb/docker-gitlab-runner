var fs = require('fs');
var https = require('https')
var httpProxy = require('http-proxy');

const proxy = httpProxy.createProxyServer({
  target: 'https://registry.git',
  secure: false
})

proxy.on('proxyRes', function (proxyRes, req, res) {
  if(proxyRes.headers && proxyRes.headers['www-authenticate']) {
    proxyRes.headers['www-authenticate'] = proxyRes.headers['www-authenticate'].replace('https://gitlab/jwt/auth',`https://${req.headers.host}/jwt/auth`)
  }
});

https.createServer({
  key: fs.readFileSync('./gitlab.registry.key'),
  cert: fs.readFileSync('./gitlab.registry.crt')
}, function (req, res) {
  console.log(`request: ${req.url}`);
  // override jwt auth method
  if(req.url.startsWith('/jwt/auth')){
      if(req.headers.authorization && req.headers.authorization.startsWith('Basic')){
        var req = https.request({
          host: 'gitlab',
          path: req.url,
          port: '443',
          headers: {authorization: req.headers.authorization},
          rejectUnauthorized : false
        }, (response) => {
          var buffer = ''
          response.on('data', function (chunk) {
            buffer += chunk;
          });

          response.on('end', function () {
            res.setHeader("Content-Type", "application/json");
            res.writeHead(200);
            res.end(buffer)
          });
        });
        req.end();
      } else {
        res.setHeader("Content-Type", "application/json");
        res.writeHead(400);
        res.end(JSON.stringify({
          error: 'proxy auth error'
        }))
      }
  } else {
    proxy.web(req, res);
  }
}).listen(443, '0.0.0.0');
console.log('server listen on: 0.0.0.0:443');
