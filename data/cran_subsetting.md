# Libraries.io Open Data CSVs First Look
The operations performed on the following CSVs use
[Miller](https://johnkerl.org/miller/doc/index.html), invoked as `mlr`,
probably the best command-line tool available for manipulation of large
CSV files. That being said, if un`tar`red correctly, the following are
the sizes of the CSVs:

 - `projects-1.4.0-2018-12-22.csv`:
```bash
$ wc -l projects-1.4.0-2018-12-22.csv
 3333927
```
and after filtering for just packages on CRAN:
```bash
$ mlr --csv filter '$Platform == "CRAN"' then uniq -n -g "ID" projects-1.4.0-2018-12-22.csv
 14456
```
which is less than 0.5% of the total.

 - `dependencies-1.4.0-2018-12-22.csv`:
```bash
$ wc -l dependencies-1.4.0-2018-12-22.csv
 105811885
```
records. However, those that pertain to CRAN only number
```bash
$ mlr --csv filter '$Platform == "CRAN"' then uniq -n -g "ID" dependencies-1.4.0-2018-12-22.csv
 370562
```
, a 3-orders-of-magnitude reduction in data.

 - `versions-1.4.0-2018-12-22.csv`:
There are
```bash
$ mlr --icsv --opprint filter '$Platform == "CRAN"' then uniq -n -g "ID" versions-1.4.0-2018-12-22.csv
 80767
```
versions of some project on CRAN, and

```bash
$ mlr --icsv --opprint filter '$Platform == "CRAN"' then uniq -n -g "Project ID" versions-1.4.0-2018-12-22.csv
 14429
```
project IDs corresponding to those versions on CRAN, which works out to
5.6 versions per project ID on average.

## Selecting CRAN Data from Open Data CSVs
One of the most charming idiosyncrasies of `mlr` is its `then`
functionality; in the Unix style of `|`ing the output of one executable
into another, Miller chains
operations on what it calls "streams" of data. For example, for each of
the below, the three operations:
  1. Rename CSV headers to replace space with underscore
  2. Filter the resultant CSV to just the records where the `Platform`
  header has value `"CRAN"`
  3. Write the resulting CSV to a new file name, stripping the version
  and date information from the file name and prepending with `cran_`

are performed, and Bash redirects the output so the file specified.

### Projects
File name: `projects-1.4.0-2018-12-22.csv'
```bash
$ mlr --csv rename 'Created Timestamp,Created_Timestamp,Updated Timestamp,Updated_Timestamp,Homepage URL,Homepage_URL,Repository URL,Repository_URL,Versions Count,Versions_Count,Latest Release Publish Timestamp,Latest_Release_Publish_Timestamp,Latest Release Number,Latest_Release_Number,Package Manager ID,Package_Manager_ID,Dependent Projects Count,Dependent_Projects_Count,Last synced Timestamp,Last_Synced_Timestamp,Dependent Repositories Count,Dependent_Repositories_Count,Repository ID,Repository_ID' then filter '$Platform == "CRAN"' then cut -x -f "Platform" projects-1.4.0-2018-12-22.csv > cran_projects.csv
```
### Dependencies
File name: `dependencies-1.4.0-2018-12-22.csv`
```bash
$ mlr --csv rename 'Project Name,Project_Name,Project ID,Project_ID,Version Number,Version_Number,Version ID,Version_ID,Dependency Name,Dependency_Name,Dependency Platform,Dependency_Platform,Dependency Kind,Dependency_Kind,Optional Dependency,Optional_Dependency,Dependency Requirements,Dependency_Requirements,Dependency Project ID,Dependency_Project_ID' then filter '$Platform == "CRAN" && $Dependency_Platform == "CRAN"' then cut -x -f "Platform,Dependency_Platform" dependencies-1.4.0-2018-12-22.csv > cran_dependencies.csv
```
### Versions
File name: `versions-1.4.0-2018-12-22.csv`
```bash
$ mlr --csv rename 'Project Name,Project_Name,Project ID,Project_ID,Published Timestamp,Published_Timestamp,Created Timestamp,Created_Timestamp,Updated Timestamp,Updated_Timestamp' then filter '$Platform == "CRAN"' then cut -x -f "Platform" versions-1.4.0-2018-12-22.csv > cran_versions.csv
```
