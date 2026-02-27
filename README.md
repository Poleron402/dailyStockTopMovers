## Weekly Stock Top Movers
[Access Website](http://polmejiapennymactest.s3-website-us-west-1.amazonaws.com/)
A full stack application deployed using serverless data pipeline on [AWS](https://docs.aws.amazon.com/).<br>
<details>
<summary>Tools used</summary>

* <mark>AWS Lambda</mark> *to run database population and retrieval logic*
* <mark>AWS DynamoDB</mark> *to store stock data*
* <mark>AWS EventBridge</mark> *to schedule the stock data population lambda*
* <mark>AWS API Gateway</mark> *to create an API endpoint that triggers database data retrieval function*
* <mark>AWS S3 bucket</mark> *to serve the React frontend*
* <mark>Python</mark> *the language in which lambda functions are written*
* <mark>React</mark> *for frontend*
</details>
<img width="2111" height="1040" alt="image" src="https://github.com/user-attachments/assets/93b85b6f-b403-49b5-89fc-b9a07b510f2a" />


>### Setup Prerequisites
>#### Aws CLI
>- Install AWS CLI on the OS by following [these instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
>- Run `aws configure` and follow the prompt to authenticate yourself. This will allow you to work with AWS from the terminal.
>#### Massive API key
> - Create a .env file in the `infra/` directory. 
> - Create a free API key on [massive.com](https://massive.com/).
> - Store the API key in the following fashion: ```export TF_VAR_massive_api_key=YOUR_KEY```
> #### Other `.env` variables
> - Store your preferred AWS region as `export TF_VAR_aws_region=your-region`
> - Store your database name as `export TF_VAR_database_name=your_dbname`
>- Store your S3 bucket name as `export TF_VAR_bucket_name=your_unique_bucket_name`
> > [!CAUTION] 
> > The S3 bucket names must be globally unique across all AWS accounts and all AWS Regions within a given partition.

>### How to run and load the infrastructure
>A [Makefile](https://github.com/Poleron402/dailyStockTopMovers/blob/main/Makefile) was created to consolidate commands and save time. Ensure [make](https://man7.org/linux/man-pages/man1/make.1.html) is installed on your system. If on Windows, consider using WSL. <br>
>-- Under `infra/` directory, run `terraform init`.
>-- Prepare `be-save` for deployment by running `make prepare_save`.<br>
>-- Prepare `be-fetch` for deployment by running `make prepare_fetch`.<br>
>⬆️ These two commands create a subdirectory called **lambda/** and install the required python modules into that subdirectory. This makes it easier for Terraform to zip the code with all the dependencies.<br>
>-- Load all the environment variables and check the planned changes by running `make load_and_plan`.<br>
>-- Apply the changes by running `make load_infra`. This auto approves all the changes, and therefore is not suggested. Consider changing into `infra/` directory and running `terraform apply` to review and approve infrastructure changes. <br>
>-- Build the React application (which will generate a `dist/` folder) and sync (recursively copy the files) the `dist/` folder with the s3 bucket instance.
>-- Lastly, retrieve the URL for created s3 bucket, and manually paste it into the frontend code under `fe/src/App.tsx` line 19.

## Tradeoffs
The main tradeoffs were done due to free API tier limitations.
<details>
<summary>Tradeoff #1</summary>
Massive API only allows 5 requests per minute. The response does not return any indicator of how long the cooldown is, so the lambda that fetches stock data calls `time.sleep(12)`, which stops the program for 12 seconds before calling again (we have 6 tickers to call)
</details>
<details>
<summary>Tradeoff #2</summary>
Massive API returns daily stock summary later in the evening, and the documentation is not clear or consistent as to when that time is. Therefore, the database is updated everyday at 22:05 PST.
</details>
<details>
<summary>Tradeoff #3</summary>
Not related to the API, but had issue finding a way to inject API Gateway endpoint into the frontend. Therefore, in the instructions, it is said to populate it manually.
</details>


## Challenges
The main initial challenges included not being faniliar with Terraform. Therefore, it took some additional time in the beginning to familiarize myself with the tool. This project was a great introduction to the services! <br>
The main **performance** challenge is in the way DynamoDB database is set up. I was planning on creating a sorting key, so that retrieval by date is more efficient, however, I ran into an issue and settled on the regular search by date rather than fetching several responses for the last 7 days.

## Needed Improvements
* Since the istructions specified not accruing the cost for the project, I did not get a custom domain for the web page. Without a custom domain, I cannot enable SSL/TLS certificates to make the webpage more secure.
* Error handling. If the stock API fails, the EventBridge reruns it up to five times. The rate limiting per minute is mitigated with `time.sleep(12)`
* Currently, if the database has fewer than 7 entries, API Gateway will timeout and return an error, instead of returning partial data.

