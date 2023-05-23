# dbt_docker

[![Deploy to ECR](https://github.com/henrikig/dbt_docker/actions/workflows/build-dbt-image.yaml/badge.svg)](https://github.com/henrikig/dbt_docker/actions/workflows/build-dbt-image.yaml)

This is a template repository for building and pushing a dbt project with Docker
to AWS ECR.

### Running the dbt project locally with Docker

In addition to running the project with regular dbt commands, this project is
set up to be run with Docker.

Ensure you have Docker installed and running, run `docker ps` to see if Docker
is running. the output shouls be something like:

```sh
CONTAINER ID   IMAGE      COMMAND                  CREATED       STATUS       PORTS                    NAMES
...
```

##### Set up local postgres database with Docker

To test the dbt project you will need a database. For test purposes, it is
sufficient to set up a local database with the `postgres` Docker image:

```sh
docker run -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -p "5432:5432" -d postgres
```

This creates a postgres database with a user `postgres` and password `password`
listening on port 5432.

##### Build and run the container

The [Dockerfile](Dockerfile) in this repository defines the dbt image. Simply
put, this Dockerfile downloads the official dbt postgres Docker image which
includes the dbt postgres adapter along with other necessary dependencies. Then,
the dbt profile and dbt project are copied into their respective locations.

To build the image, run the following command:

```sh
docker build -t dbt_docker .
```

This builds the Docker image as specified in the Dockerfile. Run
`docker image list` to see that the image has been created.

To start a container using the specified image, run the following command:

```sh
docker run --network=host -e DBT_USER=postgres -e DBT_ENV_SECRET_PASSWORD=password dbt_docker
```

The [dbt profile](./.dbt/profiles.yml) copied into the container looks for the
dbt postgres username and password as environment variables, which is why we
pass them along with the `docker run` command. This is both to avoid having the
username and password in plain sight in the repository, as well as it allows for
adjusting the database connection when running the container.

It is also possible to create a `.env` file and use this as input to the
container instead. Create a file called `.env` in the root of this repository
and paste the following content:

```python
DBT_USER=postgres
DBT_ENV_SECRET_PASSWORD=password
```

And then start the container with:

```sh
docker run --network=host --env-file=.env dbt_docker
```

This comes in handy when the number of environment variables to pass to the
container increases.

### Building the image with Github actions

This project also sets up a CI pipeline with Github actions, building the image
and pushing it to AWS ECR. See
[this workflow](./.github/workflows/build-dbt-image.yaml) for reference.

In order for the action to work, a role on AWS with ECR actions allowed needs to
be defined. The following is an example of a policy that gives rights for
performing different actions to ECR, including pushing an image:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository",
        "ecs:DescribeTaskDefinition"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
```

In addition, a trust policy needs to be set up, allowing the given repository to
assume this role. This trust policy depends on a Github oidc provider being set
up, see
[here](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
for more information.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789123:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:ref:refs/heads/main"
        }
      }
    }
  ]
}
```
