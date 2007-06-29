<cfcomponent name="codeService">
	<cffunction name="init" access="public" output="false" returntype="codeService">
		<cfreturn this />
	</cffunction>
	
	<cffunction name="configure" access="public" output="false" returntype="void">
		<cfargument name="dsn" required="true" type="string" />
		<cfargument name="basePath" required="true" type="string" />
		<cfargument name="projectPath" type="string" required="no" default="" />
		<cfargument name="rootPath" required="no" type="string" default="" />
		
		<cfset var separator = getOSFileSeparator() />
		<cfset variables.basePath = expandPath(arguments.basePath) />
		<cfset variables.dsn = arguments.dsn />
		<cfset variables.projectPath = variables.basePath & 'projects' & separator & arguments.projectPath & separator />
		<cfif len(arguments.rootPath)>
			<cfset variables.rootPath = arguments.rootPath />
		<cfelse>
			<cfset variables.rootPath = "" />
		</cfif>
		<cfset readConfig() />
	</cffunction>
	
	<cffunction name="getComponents" access="public" output="false" returntype="array">
		<cfargument name="xmlTable" required="true" type="xml" />
		
		<cfset var cfcIndex = 0 />
		<cfset var separator = getOSFileSeparator() />
		<cfset var template = "" />
		<cfset var name = "" />
		<cfset var filename = "" />
		<cfset var content = "" />
		<cfset var thisRootPath = "" />
		<cfset var objPage = "" />
		<cfset var arrComponents = arrayNew(1) />
		<cfset var root = arguments.xmlTable.root />
		
		<!--- loop through cfc types --->
		<cfloop from="1" to="#arrayLen(variables.config.generator.xmlChildren)#" index="cfcIndex">
			<cfset template = buildTemplate(variables.config.generator.xmlChildren[cfcIndex]) />
			<cfset name = variables.config.generator.xmlChildren[cfcIndex].xmlName />
			<cfif structKeyExists(variables.config.generator.xmlChildren[cfcIndex].xmlAttributes,"templateType") and variables.config.generator.xmlChildren[cfcIndex].xmlAttributes.templateType eq "cfm">
				<!--- write the cfmm to a hard file so it can be dynamically evaluated --->
				<cffile action="write" file="#expandPath('/tmp.txt')#" output="#template#" />
				<cfsavecontent variable="content">
					<cfinclude template="/tmp.txt" />
				</cfsavecontent>
				<cfset content =  replaceList(content,"<%,%>,%","<,>,##") />
				<cffile action="delete" file="#expandPath('/tmp.txt')#" />
			<cfelse>
				<cfset content = xmlTransform(arguments.xmlTable,template) />
			</cfif>
			<cfset thisRootPath = "" />
			<cfif len(variables.rootPath) and structKeyExists(variables.config.generator.xmlChildren[cfcIndex].xmlAttributes,"fileType")>
				<!--- if text to append to file name is specified use it otherwise default to the object type name --->
				<cfif structKeyExists(variables.config.generator.xmlChildren[cfcIndex].xmlAttributes,"fileNameAppend")>
					<cfset thisRootPath = variables.rootPath & variables.config.generator.xmlChildren[cfcIndex].xmlAttributes.fileNameAppend & "." & variables.config.generator.xmlChildren[cfcIndex].xmlAttributes.fileType  />
				<cfelse>
					<cfset thisRootPath = variables.rootPath & ucase(left(name,1)) & right(name,len(name)-1) & "." & variables.config.generator.xmlChildren[cfcIndex].xmlAttributes.fileType  />
				</cfif>
			</cfif>
			<cfset objPage = createObject("component","cfcgenerator.com.cf.model.code.generatedPage").init(name,template,content,thisRootPath) />
			<cfset arrayAppend(arrComponents,objPage) />
		</cfloop>
		<cfreturn arrComponents />
	</cffunction>
	
	<cffunction name="readConfig" access="private" output="false" returntype="void">		
		<cfset var configXML = "" />
		
		<cfif fileExists(variables.projectPath & "yac.xml")>
			<cfset variables.usePath = variables.projectPath />
			<cffile action="read" file="#variables.projectPath & 'yac.xml'#" variable="configXML" charset="utf-8" />
		<cfelse>
			<cfset variables.usePath = variables.basePath />
			<cffile action="read" file="#variables.basePath & 'yac.xml'#" variable="configXML" charset="utf-8" />
		</cfif>
		<cfset variables.config = xmlParse(configXML) />
	</cffunction>
	
	<cffunction name="buildTemplate" access="private" output="false" returntype="string">
		<cfargument name="typeXML" required="true" type="xml" />
		
		<cfset var returnTemplate = "" />
		<cfset var innerTemplate = "" />
		<cfset var tmpTemplate = "" />
		<cfset var i = 0 />
		<cfset var separator = getOSFileSeparator() />
		<cfset var templateType = "xsl" />
		
		<cfif structKeyExists(typeXML.xmlAttributes,"templateType")>
			<cfset templateType = typeXML.xmlAttributes.templateType />
		</cfif>
		
		<!--- loop through each include and append it to the inner XSL/CFML --->
		<cfloop from="1" to="#arrayLen(arguments.typeXML.xmlChildren)#" index="i">
			<cffile action="read" file="#variables.usePath & arguments.typeXML.xmlName & separator & arguments.typeXML.xmlChildren[i].xmlAttributes.file#" variable="tmpTemplate" charset="utf-8" />
			<cfset innerTemplate = innerTemplate & chr(13) & chr(13) & tmpTemplate />
		</cfloop>
		<!--- read the base template --->
		<cffile action="read" file="#variables.usePath & arguments.typeXML.xmlName & '.' & templateType#" variable="tmpTemplate" charset="utf-8" />
		<cfset returnTemplate = replaceNoCase(trim(tmpTemplate),"<!-- custom code -->",trim(innerTemplate)) />
		<cfreturn trim(returnTemplate) />
	</cffunction>
	
	<!--- code supplied by Luis Majano --->
	<cffunction name="getOSFileSeparator" access="public" returntype="any" output="false" hint="Get the operating system's file separator character">
        <cfscript>
        var objFile =  createObject("java","java.lang.System");
        return objFile.getProperty("file.separator");
        </cfscript>
    </cffunction>
</cfcomponent>