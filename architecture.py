#!/usr/bin/env python3
"""
AWS DevSecOps Capstone - Architecture Diagram
Generates architecture.png using the `diagrams` library (Diagram as Code).

Run:  python3 architecture.py
Requires:  pip install diagrams  +  graphviz (the `dot` binary)
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import VPC, InternetGateway, NATGateway, ALB, PublicSubnet, PrivateSubnet
from diagrams.aws.compute import ECS, Fargate
from diagrams.aws.database import RDS
from diagrams.aws.security import SecretsManager, IAMRole
from diagrams.aws.storage import S3
from diagrams.aws.devtools import Codepipeline
from diagrams.aws.management import Cloudwatch
from diagrams.onprem.vcs import Github
from diagrams.onprem.iac import Terraform
from diagrams.onprem.client import Users

graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "spline",
}

with Diagram(
    "AWS DevSecOps Capstone - URL Shortener",
    filename="architecture",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
):
    users = Users("Users")

    # --- CI/CD pipeline (left side) ---
    with Cluster("CI/CD (keyless via OIDC)"):
        gh = Github("GitHub Actions\npush -> test -> build")
        tf = Terraform("Terraform\n(infra as code)")
        role = IAMRole("OIDC Role\n(no stored keys)")
        gh >> Edge(label="assumes") >> role

    state = S3("S3\nremote state\n(encrypted)")
    tf >> Edge(style="dashed", label="state") >> state

    # --- The AWS environment ---
    with Cluster("AWS VPC (multi-AZ)"):
        igw = InternetGateway("IGW")
        nat = NATGateway("NAT")

        with Cluster("Public subnets"):
            alb = ALB("ALB")

        with Cluster("Private subnets"):
            with Cluster("ECS Fargate"):
                svc = Fargate("URL Shortener\n(blue/green)")
            db = RDS("PostgreSQL")

        secret = SecretsManager("Secrets Manager\nDB password")

        users >> Edge(label="HTTPS") >> igw >> alb >> svc
        svc >> Edge(label="SQL") >> db
        svc >> Edge(style="dashed", label="reads pw") >> secret
        svc >> Edge(style="dotted", label="pull image") >> nat

    # pipeline deploys into the cluster
    role >> Edge(label="deploy") >> svc

    # observability
    cw = Cloudwatch("CloudWatch\nlogs")
    svc >> Edge(style="dotted") >> cw
