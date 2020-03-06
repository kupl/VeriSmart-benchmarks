import os
import shutil
import time

def run_echidna(p):
    (filename, contract, rep, extra_args) = p
    coverage = None
    
    cdir = "temp/echidna_"+filename.replace("/","_")+"_"+str(rep)+".dir"
    shutil.rmtree(cdir, ignore_errors=True)
    os.mkdir(cdir)
    os.chdir(cdir)
    os.mkdir("corpus")

    config = open("../../tools/echidna.yaml","r").read()

    with open("echidna.yaml", "w+", newline='') as f:
        f.write(config)
        if (extra_args is not None):
            f.write(extra_args)

    cmd = 'echidna-test ../../'+filename+' --contract '+contract+' --config echidna.yaml > echidna.out 2> echidna.err'
    start = time.time()
    os.system(cmd)
    end = time.time()
    with open("echidna.out", newline='') as f:
        for l in f.readlines():
            l = l.replace('\n','')
            if "Unique instructions: " in l:
                coverage = int(l.split(" ")[2])
    
    os.chdir('../..')
    return (filename, coverage, rep, end - start)
