MATCH (:Language {name: 'R'})<-[:IS_WRITTEN_IN]-(p:Project)<-[:HOSTS]-(:Platform {name: 'CRAN'})
WHERE p.name in ["Rcpp","ggplot2","MASS","dplyr","plyr","stringr","Matrix","magrittr","httr","jsonlite"]
MATCH (c:Contributor)-[ct:CONTRIBUTES_TO]->(p)
WITH c, COUNT(ct) AS num_top_10_contributed_to
WHERE num_top_10_contributed_to > 0
RETURN c, num_top_10_contributed_to ORDER BY num_top_10_contributed_to DESC
;
