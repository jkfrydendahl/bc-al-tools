I would like your help to analyze the CAL_OBJECTS_INPUT.txt file found in this folder. It contains all the code from a specific Navision platform (see version in the input file), and I need to determine how many customizations have been made, as part of preparations for an upgrade to Business Central SaaS (see version in the input file).

If a user asks you to run this markdown instruction, first ask them to carefully read through the CAL_OBJECTS_INPUT.txt template.
They should ensure that they have filled out all required information in the file and here in the prompt before proceeding.

When asked to run the analysis_prompt.md, firstly do so without analyzing the input file, then determine if you need any more information to carry out the requested analyzis adequately, and then create a checklist of work to be done before you proceed.

**Here's what we should do:**

- Create a PowerShell script that can scan through the entire file and look for patterns like the ones described below and list the output from the script in a simple text file, showing an overview of custom objects, modified objects and so on.
- If an exiting PowerShell script exists in this folder, update it to use the patterns, object ranges, keywords etc. listed in this prompt (provided they are not the same).
- Once the script is ready, you run it. If there are any errors, you fix them and try again.
- Continue this process until the entire file has been successfully processed.
- Note: The file is long - it contains 3.211.082 lines. It is VERY important to ensure that we actually scan through the entire file.

**The patterns we need to look for are as follows:**

Note that I've marked with **bold** which parts in each pattern that denotes a customization.

- Custom objects, fields, variables etc. in object range 50.000 - 59.000.
- Objects with customizations listed in the version list.
  - Example: OBJECT Report 6636 Purchase - Return Shipment, in object property:
    - Version List=NAVW110.00,**T724944**;
- Objects with customizations in code (usually wrapped in comments to show where the customization begins and ends)
  - Example: OBJECT Table 48 Invt. Posting Buffer, on line 31.107-31.110
    - **//001:>>**
    - LineNo := PurchLine."Line No.";
    - Description := PurchLine.Description;
    - **//001:<<**
- Keywords: **BREDANA**, **9A**
- Any lines with text fitting the pattern: \[number\] \[abbreviation\]
  - Example: **01 LAM**
- Any lines with text fitting the pattern: \[number\].\[abbreviation\]
  - Examples: **02.SHI**, **01.CST**, **02.KTH**, **03.PAN**

Of course, keep in mind that these patterns are not definite - there might be similar cases that we need to look for as well.