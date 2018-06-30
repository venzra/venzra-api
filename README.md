## Venzra API

Venzra commerce solution - API

[![CircleCI](https://circleci.com/gh/sysen-limited/venzra-api.svg?style=svg&circle-token=51b652522428b98fa9f056b136214bcf60f481e2)](https://circleci.com/gh/sysen-limited/venzra-api)

### Overview

This is the API which will back all Venzra products and is designed as a highly available / scalable solution.

### Requirements

- Node 8
- Mongo DB 3.6 (or newer)

### Available commands

- npm install  
  Installs required dependencies, must always be run before any other commands will work

- npm run test:local  
  This uses express directly to execute the functional tests
  
- npm start  
  Runs serverless offline locally to allow for development of UI
  
- npm deploy:test  
  Performs a deployment to the test environment
  
### Deployment

This is performed via Circle CI and uses the scripts `npm run test:ci` and `npm run deploy:prod` to perform required checks and deployments
