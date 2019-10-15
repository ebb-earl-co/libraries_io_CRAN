#!/usr/bin/env python
# -*- coding: utf-8 -*-

from sqlite3 import connect, Row
import sys

from requests_html import AsyncHTMLSession, HTMLSession

available_packages_url = \
   "https://cran.r-project.org/web/packages/available_packages_by_name.html"


def main(argv=None):
    if argv is None:
        argv = sys.argv

    DB, table = argv[1:]

    # First, get the R packages, the CRAN package pages of which to request
    with connect(DB) as conn:
        conn.row_factory = Row
        cur = conn.execute(
            f"SELECT project_name AS name FROM {table} "
            "WHERE LENGTH(contributors)=2;"
        )
        r_projects_without_contributors = \
            list(map(lambda row: row.get("name"), cur))

    # Then, get the HTML of the CRAN Available Packages page
    session = HTMLSession()
    cran_ = session.get(available_packages_url)

    # Find the link element on the CRAN avaiable packages page corresponding to
    # the R project names. This link has the project name between / /
    link_elements = map(
        lambda h=cran_.html: h.find(f"a[href*=\/{rproj}\/]", first=True),
        r_projects_without_contributors
    )

    # Each link element only has the 1 absolute link, but it's a set object
    urls_to_request =  map(lambda el: next(iter(el.absolute_links)),
                           link_elements)

    # Send a GET request to the project's link
    package_pages = map(lambda url, s=session: s.get(url),
                        urls_to_request)

    # Find the first <table> object on the page
    first_table_elements = \
        map(lambda response: response.html.find('table', first=True),
            package_pages)

    # Get all the <tr> elements in the table: these are table ROWs
    tr_elements = \
        map(lambda table_el: table_el.find('tr'), first_table_elements)

    # Okay, this is hairy: go through the <tr> elements, and get the one and the
    # one following it if the <tr> element has a sub-<td> element that has text
    # 'Author':. Whew
    author_tr__maintainer_tr = \
        map(lambda tr: next((tr[i], tr[i+1]) for i, tr_el in enumerate(tr)
                            if any(td.text == "Author:" for td in tr_el.find('td'))),
            tr_elements)

    # Extract the second <td> element from each of the <tr> elements in the
    # tuple `author_tr__maintainer_tr
    author_text__maintainer_text = \
        map(lambda tup: tuple(map(lambda td: td.find('tr')[1])),
            author_tr__maintainer_tr)


