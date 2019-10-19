// Dependency_Kind for CRAN packages can be one of: 'depends' (which is useless
// because it always denotes the version of `R` itself); 'suggests', which is also
// not helpful because it's arbitrarily provided by the author; and 'imports'
// which is a dependence in the sense we are going for

CALL apoc.load.csv("cran_dependencies.csv", {ignore:["ID","Version_Number","Dependency_Requirements"]}) yield map WHERE map["Dependency_Kind"] = "imports"
MATCH (v:Version {ID: toInteger(map["Version_ID"])}) MATCH (proj:Project {ID: toInteger(map["Dependency_Project_ID"])}) MERGE (proj)<-[d:DEPENDS_ON]-(v) ON CREATE SET d.optional=apoc.convert.toBoolean(map["Optional_Dependency"])
;
