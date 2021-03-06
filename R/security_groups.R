#' @rdname security_groups
#' @title Security Groups
#' @description Describe, create, and delete Security Groups
#' @details Security groups provide a layer of security for a Virtual Private Cloud (VPC) for an EC2 instance or set of instances. These can be used in tandem with or in lieu of network Access Control Lists (ACLs) (see [describe_netacls()]). Any given instance can be in multiple security groups, which can be confusing.
#' @template sgroup
#' @param name A character string (max 255 characters) specifying a security group name.
#' @param description A character string specifying a security group description.
#' @param vpc A character string specifying a VPC Id (required for a VPC).
#' @template filter
#' @template dots
#' @return For `describe_sgroups` and `create_sgroup`, a list of objects of class \dQuote{ec2_security_group}. For `delete_sgroup`, a logical.
#' @references
#' <http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html>
#' <http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSecurityGroups.html>
#' <http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateSecurityGroup.html>
#' <http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DeleteSecurityGroup.html>
#' @examples
#' \dontrun{
#' describe_sgroups()
#' # create a generic security group
#' sg1 <- create_sgroup("test_group", "example security group")
#' delete_sgroup(sg1)
#'
#' # create a security group within a VPC
#' ## setup the VPC
#' vpc <- allocate_ip("vpc")
#' vpc <- describe_ips(vpc)[[1]]
#' sg2 <- create_sgroup("test_group2", "new security group", vpc = vpc)
#' }
#' @seealso [authorize_ingress()]
#' @keywords security
#' @export
describe_sgroups <- function(sgroup = NULL, name = NULL, filter = NULL, ...) {
    query <- list(Action = "DescribeSecurityGroups")
    if (!is.null(sgroup)) {
        if (inherits(sgroup, "ec2_security_group")) {
            sgroup <- list(get_sgid(sgroup))
        } else if (is.character(sgroup)) {
            sgroup <- as.list(get_sgid(sgroup))
        } else {
            sgroup <- lapply(sgroup, get_sgid)
        }
        names(sgroup) <- paste0("GroupId.", 1:length(sgroup))
        query <- c(query, sgroup)
    }
    if (!is.null(name)) {
        if (inherits(name, "ec2_security_group")) {
            name <- list(get_sgname(name))
        } else if (is.character(name)) {
            name <- as.list(get_sgname(name))
        } else {
            name <- lapply(name, get_sgname)
        }
        names(name) <- paste0("GroupName.", seq_along(name))
        query <- c(query, name)
    }
    if (!is.null(filter)) {
        query <- c(query, .makelist(filter, type = "Filter"))
    }
    r <- ec2HTTP(query = query, ...)
    return(unname(lapply(r$securityGroupInfo, function(z) {
        structure(flatten_list(z), class = "ec2_security_group")
    })))
}

#' @rdname security_groups
#' @export
create_sgroup <- function(name, description, vpc = NULL, ...) {
    query <- list(Action = "CreateSecurityGroup", 
                  GroupName = name,
                  GroupDescription = description)
    if (!is.null(vpc)) {
        query$VpcId <- get_vpcid(vpc)
    }
    r <- ec2HTTP(query = query, ...)
    out <- list(groupId = r$groupId[[1]], groupName = name, groupDescription = description)
    return(structure(out, class = "ec2_security_group"))
}

#' @rdname security_groups
#' @export
delete_sgroup <- function(name = NULL, sgroup = NULL, ...) {
    query <- list(Action = "DeleteSecurityGroup")
    if (!is.null(sgroup)) {
        if (inherits(sgroup, "ec2_security_group")) {
            sgroup <- list(get_sgid(sgroup))
        } else if (is.character(sgroup)) {
            sgroup <- as.list(get_sgid(sgroup))
        } else {
            sgroup <- lapply(sgroup, get_sgid)
        }
        names(sgroup) <- paste0("GroupId.", 1:length(sgroup))
        query <- c(query, sgroup)
    }
    if (!is.null(name)) {
        if (inherits(name, "ec2_security_group")) {
            name <- list(get_sgname(name))
        } else if (is.character(name)) {
            name <- as.list(get_sgname(name))
        } else {
            name <- lapply(name, get_sgname)
        }
        names(name) <- paste0("GroupName.", 1:length(name))
        query <- c(query, name)
    }
    r <- ec2HTTP(query = query, ...)
    if (r$return[[1]] == "true") {
        return(TRUE)
    } else {
        return(FALSE)
    }
}

print.ec2_security_group <- function(x, ...) {
    cat("ownerId:          ", x$ownerId, "\n")
    cat("groupId:          ", x$groupId, "\n")
    cat("groupName:        ", x$groupName, "\n")
    cat("groupDescription: ", x$groupDescription, "\n")
    cat("vpcId:            ", x$vpcId , "\n")
    cat("ipPermissions:       ", length(x$ipPermissions), "\n")
    cat("ipPermissionsEgress: ", length(x$ipPermissionsEgress), "\n")
    invisible(x)
}
