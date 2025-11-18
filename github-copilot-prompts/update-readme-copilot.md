
Update the Readme of this project. Include only the following sections:
- Introduction (Overall summary. Kep concise while explaining the extension's purpose and key features).
- Feature Areas (Short description of each feature area found within the /src folder, in a list format).
- Documentation
  - Software Dependencies (Essential development tools and BC requirements).
  - Project Documentation (List of documentation files found in the /document or /aidocs folder).
  - Reference Documentation (Links to external documentation - see below for minimum)

I want you to closely adhere to the following guidelines when building the readme:
- List all feature areas on the "same level" in the list. For example, the most important feature areas may be listed in a /workflows folder.
  In this case, just list the separate feature areas, don't group them into a workflows sub-list.
- Incorporate into the documentation section(s) links to relevant /documentation files, 
  so it is easy for the reader to see that the project is documented in further detail here. 
- Make sure you include, under the Project Documentation, ONLY files from the /documentation and/or /aidocs folder(s)
  that are prefixed by a number (e.g. 01_*.md). For example, don't include index.md or project_analysis.md files. 
- If the same documentation files exist in both folders, list the contents of the /documentation folder.
- For all external documentation (e.g. links to MS docs, VS code extensions etc.), ALWAYS include link to that ressource.

For software dependencies, ONLY list:
- The minimum version of Business Central required.
- The minimum runtime version.
- The Microsoft AL language extension for VS Code (with link).
- App dependencies listed in the app.json

Minimum required links for Reference Documentation (add more if you think it's relevant):
- [Microsoft AL Documentation](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dev-overview)
- [9A DevOps Wiki: Source Control and Dev Standards](https://dev.azure.com/Dynalogic/9A%20Intern/_wiki/wikis/9A-Intern.wiki/14/Source-Control-and-Development-Standards)
- [Business Central Extension Development](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-reference-overview)
