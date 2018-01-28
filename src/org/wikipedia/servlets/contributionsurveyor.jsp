<%--
    @(#)contributionsurveyor.jsp 0.01 27/01/2018
    Copyright (C) 2011 - 2018 MER-C

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--%>

<%@ include file="header.jsp" %>
<%@ page pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.net.URLEncoder" %>

<%
    request.setAttribute("toolname", "Contribution surveyor (beta)");

    String user = request.getParameter("user");
    boolean nominor = (request.getParameter("nominor") != null);
    boolean noresults = false;

    String homewiki = request.getParameter("wiki");
    if (homewiki == null)
        homewiki = "en.wikipedia.org";
    else
        homewiki = ServletUtils.sanitizeForAttribute(homewiki);
    
    String bytefloor = request.getParameter("bytefloor");
    if (bytefloor == null)
        bytefloor = "150";
    else
        bytefloor = ServletUtils.sanitizeForAttribute(bytefloor);
    
    if (user != null)
    {
        // get results
        Wiki wiki = Wiki.createInstance(homewiki);
        wiki.setQueryLimit(30000); // 60 network requests
        ContributionSurveyor surveyor = new ContributionSurveyor(wiki);
        surveyor.setIgnoringMinorEdits(nominor);
        surveyor.setMinimumSizeDiff(Integer.parseInt(bytefloor));
        Map<String, Map<String, List<Wiki.Revision>>> survey = surveyor.contributionSurvey(new String[] { user }, Wiki.MAIN_NAMESPACE);
        Map<String, List<Wiki.Revision>> usersurvey = survey.entrySet().iterator().next().getValue();
        noresults = usersurvey.isEmpty();

        if (!noresults)
        {
            // create download prompt
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment; filename=" + URLEncoder.encode(user, "UTF-8") + ".txt");

            // write results
            out.println(ParserUtils.generateUserLinksAsWikitext(user));
            out.println(surveyor.formatTextSurveyAsWikitext(null, usersurvey));
            out.println(surveyor.generateWikitextFooter());
            out.flush();
            out.close();
            return;
        }
    }
%>

<!doctype html>
<html>
<head>
<link rel=stylesheet href="styles.css">
<title><%= request.getAttribute("toolname") %></title>
</head>

<body>
<p>
This tool generates a listing of a user's edits for use at <a
href="//en.wikipedia.org/wiki/WP:CCI">Contributor copyright investigations</a>
and other venues. It isolates and ranks major edits by size. A query limit of
30000 edits applies.

<p>
<form action="./contributionsurveyor.jsp" method=GET>
<table>
<tr>
    <td>User to survey:
    <td><input type=text name=user value="<%= user == null ? "" : ServletUtils.sanitizeForAttribute(user) %>" required>
<tr>
    <td>Home wiki:
    <td><input type=text name="wiki" value="<%= homewiki %>" required>
<tr>
    <td>Exclude:
    <td><input type=checkbox name=nominor value=1<%= (user == null || nominor) ? " checked" : "" %>>minor edits</input>
<tr>
    <td>Show changes that added at least:
    <td><input type=number name=bytefloor value="<%= bytefloor %>"></input> bytes
</table>
<input type=submit value="Survey user">
</form>

<%
    if (user != null && noresults)
    {
%>
<hr>
<span class="error">No edits found!</span>
<%
    }
%>
<%@ include file="footer.jsp" %>