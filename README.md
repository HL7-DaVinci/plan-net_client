# Da Vinci Plan-Net Reference Implementation

## Installation and Deployment

The client reference implementation can installed and run locally on your machine.  Install the following dependencies first:

* [Ruby 2.6+](https://www.ruby-lang.org/en/)
* [Ruby Bundler](http://bundler.io/)
* [SQLite](https://www.sqlite.org/)

And run the following commands from the terminal:

```sh
# MacOS or Linux
git clone https://github.com/HL7-DaVinci/plan-net_client
cd plan-net_client
bundle install
rails s
```

The client can then be accessed at http://localhost:3000 in a web browser.

If you would like to use a different port it can be specified when calling `rails`.  For example, the following command would host the client on port 4000:

```sh
rails s -p 4000
```

### Reference Implementation

While it is recommended that users install the client locally, an instance of the client is hosted at https://davinci-plan-net-client.logicahealth.org

Users that would like to try out the client before installing locally can use that reference implementation.

### Docker Container

If you prefer, you can also build the client application within a Docker container.  When you
run the Docker container, it will indicate the local port that should be used to access the client.

```sh
git clone https://github.com/HL7-DaVinci/plan-net_client
cd plan-net_client
docker build -t plan-net .
docker run -itP plan-net
```

## Supported Browsers

The client has been tested on the latest versions of Chrome and Safari.  

## License

Copyright 2019 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
