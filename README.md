# VeriSmart-benchmarks
VeriSmart is a safety analyzer for Ethereum smart contracts written in Solidity.
This repository contains dataset that we used for experiments in our paper.

This repository has been developed and maintained by [Software Analysis Laboratory](http://prl.korea.ac.kr/~pronto/home/) at Korea University.

## Structure of Contents
* ``benchmarks/cve``: This folder contains 487 Solidity smart contracts reported in CVE.
The 60 contracts used in [our S&P '20 paper](https://arxiv.org/abs/1908.11227) are specified in ``labels/cve_labels.csv`` (the column ``SP20``). The deduplicated 443 contracts in [our Security '21 paper](http://prl.korea.ac.kr/~ssb920/papers/sec21.pdf) are specified in ``metadata/cve-meta.csv`` (the column ``actual_order``). The sampled 300 contracts in Table 2 of [our Security '21 paper](http://prl.korea.ac.kr/~ssb920/papers/sec21.pdf) are specified in ``labels/cve_labels.csv`` (the column ``SEC21``).

* ``benchmarks/zeus``: This folder contains 25 Solidity smart contracts from public dataset provided
by the authors of [Zeus](http://pages.cpsc.ucalgary.ca/~joel.reardon/blockchain/readings/ndss2018_09-1_Kalra_paper.pdf).

* ``benchmarks/leaking_suicidal``: This folder contains 104 Solidity smart contracts with Ether-leaking and Suicidal vulnerabilities. The contracts whose names end with ``_N.sol`` (where ``N`` is one of 1,2,3) are the ones constructed by us (see [our Security '21 paper](http://prl.korea.ac.kr/~ssb920/papers/sec21.pdf) for more details). The others come from [SmartBugs repository](https://github.com/smartbugs/smartbugs).

* ``metadata``: This folder contains metadata for contracts such as names of main contracts.

* ``labels``: This folder contains ground truths for CVE-reported vulnerabilities, and Ether-leaking and Suicidal vulnerabilities.


## Related Publications
* **VeriSmart: A Highly Precise Safety Verifier for Ethereum Smart Contracts** <br/>
  [Sunbeom So](https://sites.google.com/site/sunbeomsoprl/), Myungho Lee, Jisu Park, Heejo Lee, and [Hakjoo Oh](http://prl.korea.ac.kr/~pronto/home/) <br/>
  [S&P 2020: 41st IEEE Symposium on Security and Privacy](https://www.ieee-security.org/TC/SP2020/) <br/>
  \[[pdf](https://arxiv.org/abs/1908.11227)\]

* **SmarTest: Effectively Hunting Vulnerable Transaction Sequences in Smart Contracts through Language Model-Guided Symbolic Execution** <br/>
  [Sunbeom So](https://sites.google.com/site/sunbeomsoprl/), [Seongjoon Hong](http://prl.korea.ac.kr/~june/), and [Hakjoo Oh](http://prl.korea.ac.kr/~pronto/home/) <br/>
  [Security 2021: 30th USENIX Security Symposium](https://www.usenix.org/conference/usenixsecurity21) <br/>
  \[[pdf](http://prl.korea.ac.kr/~ssb920/papers/sec21.pdf)\]


## Questions
If you have any questions, please submit issues in this repository, or send an email to sunbeom_so@korea.ac.kr.
