function fn() {
  var env = karate.env || 'dev';

  var config = {
    baseUrl: 'https://serverest.dev',
    authUrl: 'https://serverest.dev',
    timeout: 30000
  };

  // Environment-specific overrides
//   if (env == 'dev') {
//     config.baseUrl = 'https://serverest.dev';
//   } else if (env == 'prod') {
//     config.baseUrl = 'https://serverest.prod';
//     config.timeout = 60000;
//   }

  return config;
}