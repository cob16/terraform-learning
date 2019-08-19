# AWS config 
With AWS config you can add rules to your infra such as i.e. not allowing port 22 to be open.
## Note 
The AWS config can send notifications of changes via SNS. However, it does not add any message attributes. **Therefore attaching an email to this queue results in pure spam!.** Further methods to filter the message topic is required (perhaps via a lambda or a message filter in an SQS queue)
