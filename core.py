"""
Lancaster Mode Core Engine (v0.6+)
----------------------------------
Complete symbolic recursion, compression, pattern recognition,
semantic weighting, attractor simulation, motif indexing, and
visual graph export for semiotic entropy modeling.

Author: Dr. James Burton Lancaster
"""

from typing import Any, Dict, List, Tuple, Optional, Callable
import math
import hashlib
import json
import logging
from collections import defaultdict

import networkx as nx

logging.basicConfig(level=logging.INFO)

class SymbolicNode:
    def __init__(self, label: str, metadata: Optional[Dict[str, Any]] = None):
        self.label = label
        self.metadata = metadata or {}
        self.children: List["SymbolicNode"] = []

    def add_child(self, child: "SymbolicNode"):
        self.children.append(child)

    def entropy(self) -> float:
        if not self.children:
            return 0.0
        labels = [child.label for child in self.children]
        freq = {l: labels.count(l) for l in set(labels)}
        total = len(labels)
        return -sum((c/total) * math.log2(c/total) for c in freq.values())

    def weighted_entropy(self) -> float:
        base = self.entropy()
        weight = self.metadata.get("weight", 1.0)
        return base * weight

    def recursive_entropy(self) -> float:
        return self.weighted_entropy() + sum(child.recursive_entropy() for child in self.children)

    def hash(self) -> str:
        child_hashes = ''.join(sorted(child.hash() for child in self.children))
        raw = f"{self.label}:{child_hashes}"
        return hashlib.sha256(raw.encode('utf-8')).hexdigest()

    def traverse(self, func: Callable[["SymbolicNode"], None]):
        func(self)
        for child in self.children:
            child.traverse(func)

    def attractor_score(self) -> float:
        base = self.weighted_entropy()
        stability = 1.0 / (1.0 + abs(base - sum(c.entropy() for c in self.children)))
        return round(stability, 4)

class SymbolicEngine:
    def __init__(self):
        self.root_nodes: List[SymbolicNode] = []
        self.bindings: Dict[str, str] = {}
        self.recursion_policy: Dict[str, Any] = {
            "max_depth": 10,
            "entropy_threshold": 0.05
        }
        self.signature_index: Dict[str, List[SymbolicNode]] = defaultdict(list)

    def load_structure(self, data: List[Dict[str, Any]]):
        self.root_nodes = [SymbolicNode(d["label"], d.get("meta")) for d in data]

    def bind_symbols(self, alias_map: Dict[str, str]):
        self.bindings = alias_map

    def apply_bindings(self):
        def rebind(node: SymbolicNode):
            if node.label in self.bindings:
                logging.debug(f"Rebinding {node.label} -> {self.bindings[node.label]}")
                node.label = self.bindings[node.label]
        for node in self.root_nodes:
            node.traverse(rebind)

    def compress(self) -> List[Tuple[str, float, float]]:
        self.apply_bindings()
        self.mark_duplicates(self.root_nodes)
        results = []
        for node in self.root_nodes:
            h = node.hash()
            e = node.recursive_entropy()
            a = node.attractor_score()
            results.append((h, e, a))
            logging.info(f"Compressed {node.label} -> {h[:10]}..., Entropy={e:.4f}, Attractor={a:.2f}")
        return results

    def trace(self) -> None:
        def show_trace(node: SymbolicNode, depth: int = 0):
            indent = "  " * depth
            duplicate = " *DUP*" if node.metadata.get("duplicate") else ""
            attractor = f" :: Attractor={node.attractor_score():.2f}"
            print(f"{indent}- {node.label}{duplicate} [Entropy={node.weighted_entropy():.4f}]{attractor}")
            for child in node.children:
                show_trace(child, depth + 1)

        for node in self.root_nodes:
            show_trace(node)

    def export_json(self) -> str:
        def serialize(node: SymbolicNode) -> Dict:
            return {
                "label": node.label,
                "meta": node.metadata,
                "children": [serialize(c) for c in node.children]
            }
        return json.dumps([serialize(node) for node in self.root_nodes], indent=2)

    def load_from_json(self, json_str: str):
        def deserialize(data: Dict[str, Any]) -> SymbolicNode:
            node = SymbolicNode(data["label"], data.get("meta"))
            for c in data.get("children", []):
                node.add_child(deserialize(c))
            return node

        decoded = json.loads(json_str)
        self.root_nodes = [deserialize(n) for n in decoded]

    def extract_signature(self, node: SymbolicNode) -> str:
        def serialize(n: SymbolicNode) -> str:
            children_signatures = sorted(serialize(c) for c in n.children)
            return f"{n.label}({','.join(children_signatures)})"
        return serialize(node)

    def detect_motifs(self, nodes: List[SymbolicNode]) -> Dict[str, List[SymbolicNode]]:
        self.signature_index.clear()
        for node in nodes:
            node.traverse(self._index_signature)
        return {sig: nlist for sig, nlist in self.signature_index.items() if len(nlist) > 1}

    def _index_signature(self, node: SymbolicNode):
        sig = self.extract_signature(node)
        self.signature_index[sig].append(node)

    def mark_duplicates(self, nodes: List[SymbolicNode]) -> None:
        motifs = self.detect_motifs(nodes)
        for sig, group in motifs.items():
            for node in group:
                node.metadata['duplicate'] = True
                node.metadata['motif_signature'] = sig

    def export_networkx(self) -> nx.DiGraph:
        G = nx.DiGraph()

        def add_edges(node: SymbolicNode):
            node_id = node.hash()[:10]
            G.add_node(node_id, label=node.label, entropy=node.entropy(), attractor=node.attractor_score())
            for child in node.children:
                child_id = child.hash()[:10]
                G.add_node(child_id, label=child.label, entropy=child.entropy(), attractor=child.attractor_score())
                G.add_edge(node_id, child_id)
                add_edges(child)

        for root in self.root_nodes:
            add_edges(root)

        return G
