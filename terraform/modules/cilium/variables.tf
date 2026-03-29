variable "release_name" {
    type = string
}

variable "namespace" {
    type = string
}

variable "chart_repository" {
    type = string
}

variable "chart_name" {
    type = string
}

variable "chart_version" {
    type = string
}

variable "chart_values" {
    type    = list(string)
    default = []
}