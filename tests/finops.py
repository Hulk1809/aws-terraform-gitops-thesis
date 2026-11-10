"""Run: python3 tests/finops.py --self-test (no AWS credentials required)."""
import json
import re
import sys
from decimal import Decimal
from pathlib import Path


def check_cost(data):
    value = data.get("totalMonthlyCost")
    if value is None:
        raise ValueError("Missing monthly cost; refusing an unknown estimate")
    cost = Decimal(str(value))
    # ponytail: $20 list-price ceiling for one Singapore micro lab; revise after reviewed pricing changes.
    if not cost.is_finite() or not Decimal(0) <= cost <= Decimal(20):
        raise ValueError(f"Monthly list-price ceiling exceeded or invalid: {cost}")
    for project in data.get("projects", []):
        if project.get("breakdown", {}).get("totalMonthlyCost") is None:
            raise ValueError("Project estimate is incomplete")


def check_source():
    compute = Path("modules/compute-ec2/main.tf").read_text()
    assert re.search(r'instance_type\s*=\s*"t3.micro"', compute), "Only t3.micro allowed"
    assert re.search(r'volume_size\s*=\s*8\b', compute), "Only 8 GiB root disk allowed"
    sources = "\n".join(p.read_text() for p in Path("modules").rglob("*.tf"))
    assert len(re.findall(r'resource\s+"aws_instance"', sources)) == 1
    assert not re.search(r'resource\s+"aws_(nat_gateway|eip|db_instance|lb|kms_key)"', sources)
    assert not re.search(r'\b(count|for_each)\s*=', compute), "No extra EC2 replicas"


if __name__ == "__main__":
    if sys.argv[1] == "--check-source":
        check_source()
    elif sys.argv[1] == "--self-test":
        check_source()
        check_cost({"totalMonthlyCost": "19.99"})
        for value in [None, "20.01", "-1", "NaN", "Infinity"]:
            try:
                check_cost({"totalMonthlyCost": value})
            except ValueError:
                pass
            else:
                raise AssertionError(value)
    else:
        check_cost(json.loads(Path(sys.argv[1]).read_text()))
