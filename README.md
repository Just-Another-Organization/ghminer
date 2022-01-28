- [Introduction](#orgce5b0a8)
  - [How it works](#org46aa05e)
- [User Interface](#org19faa16)
- [Prepare the environment](#org27661d2)
- [Configure the miner](#org55adf18)
  - [Time intervals](#org04cceb7)
  - [Continuous update](#orge51c58d)
  - [Maximum number of events](#org6ee542d)
  - [Last update period](#org3334edc)
  - [Keyword filters](#org6ceb02c)
- [Access to saved events](#org3f45c33)
  - [Query](#org4c01919)
  - [Regex query](#org1860200)
  - [Limit events number](#orgd3efe1f)
- [Configure Mongoid](#org76f1836)
- [Examples](#org5dfd7db)



<a id="orgce5b0a8"></a>

# Introduction

JA-GHMiner, an acronym for Just Another GitHub Miner is a *Just Another* project designed to facilitate the collection and management of data from operations performed on GitHub. JA-GHMiner relies on [GH Archive](https://www.gharchive.org/), a project to record public GitHub information, archive it, and make the information easily accessible for later analysis.


<a id="org46aa05e"></a>

## How it works

JA-GHMiner is a server written in the Ruby language that provides APIs through [Sinatra](https://github.com/sinatra/sinatra). With the help of [GitHub Archive Utils](https://github.com/intersimone999/gh-archive), JA-GHMiner once started will mine all events of type &ldquo;push&rdquo; (PushEvent) in the set time interval and save the content in a MongoDB database thanks to the library [Mongoid](https://github.com/mongodb/mongoid). The entire process is done through the use of the Docker Engine to ensure a service completely isolated from the system on which it is used.


<a id="org19faa16"></a>

# User Interface

JA-GHMiner is present with a `User Interface` that in addition to allowing you to start the mining process also allows you to view the system logs.


<a id="org27661d2"></a>

# Prepare the environment

First, download the repository.

```sh
git clone https://github.com/Just-Another-Organization/JA-GHMiner.git
```

Next, access the folder and create a `.env` file.

```sh
cd JA-GHMiner
touch .env
```

Edit the `.env` file by inserting the necessary environment variables. An example of environment variables is as follows:

```sh
PORT=4567 # Server port on which the service will be accessible
UI_PORT=4568 # Port on which the User Interface will be accessible
RACK_ENV=production # Rack environment stage
MONGO_INITDB_DATABASE=ja_ghminer_database # Mongodb database name
MONGO_INITDB_ROOT_USERNAME=root_username # Mongodb root username
MONGO_INITDB_ROOT_PASSWORD=root_password # Mongodb root password
```

Finally, start the whole JA-GHMiner system with the `docker-compose` utility.

```sh
docker-compose up --build -d # or "docker compose up --build -d" for newer docker version
```

Once you have started the docker containers you will need to start the mining process. This is done by accessing the UI at `http://localhost:${UI_PORT}` and clicking on the start button.

You can also start the miner by directly calling the `/mine` API via the command:

```sh
curl -X GET 'localhost:${PORT}/mine'
```


<a id="org55adf18"></a>

# Configure the miner

The mining process can be configured thanks to the configuration file present in `lib/config/miner.yml`. The initial configuration is as follows:

```sh
miner:
  starting_timestamp:
  ending_timestamp:
  continuously_updated: true
  max_events_number:
  last_update_timestamp:
  schedule_interval: 1h
  keywords:
```


<a id="org04cceb7"></a>

## Time intervals

By default the miner downloads events for the last hour only. To set an initial time interval you can edit `miner.yml` by modifying the properties of `starting_timestamp` and `ending_timestamp` by adding the timestamps (in seconds) you want.

```sh
miner:
  starting_timestamp: 1640995200 # Mining from: 1 January 2022 00:00:00
  ending_timestamp: 1641168000 # Mining to: 3 January 2022 00:00:00
```


<a id="orge51c58d"></a>

## Continuous update

By default the miner checks and updates at regular intervals the new events on GH Archive. You can disable the continuous update via the `continuously_updated` property.

```sh
miner:
  continuously_updated: false # Continuous updating disabled
```

The update interval is configurable via `schedule_interval`.

```sh
miner:
  continuously_updated: true # Continuous update enabled
  schedule_interval: 1d # Update every day
```

See [Rufus scheduler](https://github.com/jmettraux/rufus-scheduler#scheduling-handler-instances) for possible intervals. Also, note that GH Archive updates its data at hourly intervals. Also, the data is available a few minutes after the hour so JA-GHMiner works with a 10-minute delay to overcome this issue. This means that if the update is made at `10:04`, for example, it will not take into account the data for the interval `9:00-10:00`.


<a id="org6ee542d"></a>

## Maximum number of events

Due to the large number of events that could be saved in the database, it is possible to set a maximum number of last saved events using the `max_events_number` property. This will ensure that after each update the oldest excess events will be removed to free up space.

```sh
miner:
  max_events_number: 1000 # Set the maximum number of events to 1000
```


<a id="org3334edc"></a>

## Last update period

JA-GHMiner keeps track of the last timestamp in which it performed the update to ensure that it works even if the service is stopped and restarted later. The miner automatically writes the last update time by writing the `last_update_timestamp` property. It is however possible to change this value manually in case you want to avoid updating events before a time instant.

```sh
miner:
  last_update_timestamp: 1640995200 # Update from: 1 January 2022 00:00:00
```


<a id="org6ceb02c"></a>

## Keyword filters

You can configure the system to consider only those commits that contain keywords in their message. This is done by defining the keywords under `keywords` property. Also, note that the keyword comparison is case-sensitive and space-sensitive.

```sh
miner:
  KEYWORDS:
    - 'Blockchain' # Save only messages containing the word 'Blockchain'
    - ' DLT ' # Save only messages containing the word 'DLT' with spaces next to it.
                # Example: Save 'Created DLT structure'; Do not save 'Created foo/DLT/bar structure'.
```


<a id="org3f45c33"></a>

# Access to saved events

JA-GHMiner allows you to access and query event information via two endpoints: `/query` and `/query-regex`. Both endpoints are `GET` calls that supports sending a `body` in the form of a `application/json` to define the query parameters.


<a id="org4c01919"></a>

## Query

The `/query` endpoint allows you to get the saved events that match a given string. This can be done by sending in the `query` property the string you want to get.

```sh
{
  "query": "Merged pull request" # Gets all commits in which message is present 'Merged pull request'
}
```


<a id="org1860200"></a>

## Regex query

It is possible through the `/query-regex` endpoint to get all events whose property expressed in the `field` property satisfies the regular expression in the `regex` one.

```sh
{
  "field": "payload.commits.message", # Take into account commits messages
  "regex": "Blockchain|DLT" # Regex that filters based on the presence of 'Blockchain' or 'DLT' words
}
```

The `field` property can take values based on the structure of the event entity as it is saved within the database. To know the structure of the event model you can consult `lib/mongoid/schema/event_schema.rb` or rely on the following schema in the form of `json`:

```json
{
   "id": "id",
   "repo":{
      "id": "repo.id",
      "name": "repo.name"
   },
   "payload":{
      "push_id": "payload.push_id",
      "size": "payload.size",
      "distinct_size": "payload.distinct_size",
      "ref": "payload.ref",
      "head": "payload.head",
      "before": "payload.before",
      "commits":[
         {
            "sha": "payload.commits.sha",
            "message": "payload.commits.message",
            "author":{
               "name": "payload.commits.author.name"
            }
         }
      ]
   },
   "created_at": "created_at"
}
```


<a id="orgd3efe1f"></a>

## Limit events number

For both queries, it is possible to limit the maximum number of events thanks to the `limit` property.

```javascript
{
  "field": "payload.commits.message",
  "regex": "Blockchain|DLT",
  "limit": 100 // Returns a maximum of 100 matched events
}
```


<a id="org76f1836"></a>

# Configure Mongoid

You can configure the `Mongoid` settings as you wont by configuring the `lib/config/mongoid.yml` file.


<a id="org5dfd7db"></a>

# Examples

You can find some examples of how to use JA-GHMiner features in the `examples` folder.
