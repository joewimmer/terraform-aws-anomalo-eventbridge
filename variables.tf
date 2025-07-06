variable "eventbridge_api_key" {
  description = "EventBridge API key for authentication"
  type        = string
  sensitive   = true
}

variable "event_bus_name" {
  description = "The name of the EventBridge event bus"
  type        = string
  default     = "anomalo-events"
}
