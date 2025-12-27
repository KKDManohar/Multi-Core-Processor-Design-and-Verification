import subprocess

tests = [
    {"test_name": "proc_test", "seq": "single_cycle", "txn_count": 100, "model" : "proc_scb_ref_nodel"},
    {"test_name": "proc_test", "seq": "multi_cycle", "txn_count": 100, "model" : "proc_scb_ref_nodel"},
    {"test_name": "proc_test", "seq": "single_multi_mix", "txn_count": 200, "model" : "proc_scb_ref_nodel" },

    # other block-level tests
    {"test_name": "cache_test", "seq": "default", "txn_count": 500, "model" : "cache_ref_model"},
    {"test_name": "arbiter_test", "seq": "default", "txn_count": 8, "model" : "arb_ref_model"},
    {"test_name": "cpu_test", "seq": "default", "txn_count": 1200, "model" : "cpu_ref_model"}
]

def run_cmd(cmd):
    print(f"[Run] {cmd}")
    subprocess.run(cmd, shell = True, check= True)

def run_uvm_test(test):

    test_name = test["test_name"]
    seq = test["seq"]
    txn_count = test["txn_count"]
    model = test["model"]

    print(f"Running Test: {test_name} for a seq {seq} with txn_count {txn_count} with ref_model {model}")

    with open("run_templete.do","r") as f:
        content = f.read()

    content = content.replace("TEST_NAME%",test_name)
    content = content.replace("SEQ_TYPE%",seq)
    content = content.replace("TXN_COUNT%",str(txn_count))
    content = content.replace("MODEL%",model)

    with open("run.do","w") as f:
        f.write(content)

    print(f"\n Running uvm test{test_name}, for seq {seq} with tx_count {txn_count}")

    run_cmd(f"make TEST_NAME = {test_name} SEQ = {seq}, TXN_COUNT = {txn_count} MODEL = {model} all")

if __name__ == "__main__":
    for t in tests:
        run_uvm_test(t)




