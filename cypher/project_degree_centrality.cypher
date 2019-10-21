call algo.degree(
	"MATCH (:Language {name:'R'})<-[:IS_WRITTEN_IN]-(p:Project)<-[:HOSTS]-(:Platform {name:'CRAN'}) return id(p) as id",
    "MATCH (p1:Project)-[:HAS_VERSION]->(:Version)-[:DEPENDS_ON]->(p2:Project) return id(p2) as source, id(p1) as target",
    {graph: 'cypher', write: True, writeProperty: 'degree_centrality'}
)
;
