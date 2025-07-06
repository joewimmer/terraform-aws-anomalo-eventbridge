variable "event_bus_name" {
  description = "The name of the EventBridge event bus"
  type        = string
  default     = "anomalo-events"
}


variable "ip_allow_list" {
  description = "List of IP addresses allowed to invoke the Eventbridge publisher Lambda function"
  type        = list(string)
  default     = [
    "0.0.0.0/0"
  ]
}