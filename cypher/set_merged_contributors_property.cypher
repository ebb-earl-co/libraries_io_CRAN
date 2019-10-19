MATCH (:Language {name: 'R'})<-[:IS_WRITTEN_IN]-(p:Project)<-[:HOSTS]-(:Platform {name: 'CRAN'})
SET p.merged_contributors = NULL;
