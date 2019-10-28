call algo.degree(
	"MATCH (:Language {name:'R'})<-[:IS_WRITTEN_IN]-(p:Project)<-[:HOSTS]-(:Platform {name:'CRAN'}) return id(p) as id",
    "MATCH (p1:Project)-[:HAS_VERSION]->(:Version)-[:DEPENDS_ON]->(p2:Project) return id(p2) as source, id(p1) as target",
    {graph: 'cypher', write: true, writeProperty: 'cran_degree_centrality'}
);

CREATE INDEX ON :Project(cran_degree_centrality)
;
MATCH (:Language {name: 'R'})<-[:IS_WRITTEN_IN]-(p:Project)<-[:HOSTS]-(:Platform {name: 'CRAN'})
WITH p ORDER BY p.cran_degree_centrality DESC
WITH collect(distinct p) as projects
UNWIND projects AS project
SET project.cran_degree_centrality_rank = apoc.coll.indexOf(projects, project) + 1
p
