variable "region" {
  description = "AWS régió: itt jön létre a state bucket, és ezt kapja a CI (AWS_REGION variable)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]$", var.region))
    error_message = "Érvényes AWS régió kell, pl. eu-west-1."
  }
}

variable "cluster_name" {
  description = "Az EKS cluster neve (CLUSTER_NAME variable); az apply role IAM jogai erre az előtagra szűkülnek"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,38}$", var.cluster_name))
    error_message = "Kisbetű, szám és kötőjel, legfeljebb 39 karakter (az IAM role nevek hossza miatt)."
  }
}

variable "github_owner" {
  description = "A GitHub repó gazdája (user vagy organization), pl. SziNo"
  type        = string
}

variable "github_repository" {
  description = "A GitHub repó neve owner nélkül, pl. eks-nginx-proxy-pipeline"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "A repó neve csak betűt, számot és . _ - jeleket tartalmazhat."
  }
}

variable "admin_user_arn" {
  description = "A saját IAM userem ARN-je: cluster admin lesz, hogy helyben is használhassam a kubectl-t"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:user/.+$", var.admin_user_arn))
    error_message = "IAM user ARN kell, pl. arn:aws:iam::123456789012:user/nev."
  }
}
