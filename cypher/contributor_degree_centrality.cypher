call algo.degree(
    "MATCH (:Platform {name:'CRAN'})-[:HOSTS]->(p:Project) with p MATCH (:Language {name:'R'})<-[:IS_WRITTEN_IN]-(p)<-[:CONTRIBUTES_TO]-(c:Contributor) return id(c) as id",
    "MATCH (c1:Contributor)-[:CONTRIBUTES_TO]->(:Project)-[:HAS_VERSION]->(:Version)-[:DEPENDS_ON]->(:Project)<-[:CONTRIBUTES_TO]-(c2:Contributor) return id(c2) as source, id(c1) as target",
    {graph: 'cypher', write: True, writeProperty: 'degree_centrality'}
)
;
