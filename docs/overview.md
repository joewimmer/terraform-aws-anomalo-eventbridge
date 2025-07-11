# Anomalo EventBridge Integration

Anomalo can be configured to send all check run results a webhook destination. This terraform module sets up the required resources to consume that webhook and send the results to an AWS EventBridge event bus.  From there, you can route the events to other AWS services or third-party services along with any additional processing you may want to do.

## Architecture

![Anomalo EventBridge Architecture](images/Eventbridge-arch.pmg)

## Usage

```hcl
module "anomalo_eventbridge" {
  source              = "git::https://github.com/joewimmer/terraform-aws-anomalo-eventbridge.git"
}
```


## Integrating With EventBridge

With this in place and your Anomalo account configured to send webhook events to the URL provided by this module, you can now set up an EventBridge rule to process those events.

```hcl
resource "aws_cloudwatch_event_rule" "anomalo_events" {
  name        = "anomalo-events"
  description = "Anomalo events from the webhook"
  event_pattern = jsonencode({
    source = ["com.anomalo.events"]
    })
    event_bus_name = module.anomalo_eventbridge.event_bus_name
}

