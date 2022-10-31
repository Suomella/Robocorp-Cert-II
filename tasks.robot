*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Robocorp.Vault
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             Screenshot
Library             RPA.Archive
Library             RPA.Dialogs


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${dialog}=    Input from the user
    Download the orders file    ${dialog}[url]
    Open the robot order website
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    0.2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close the browser


*** Keywords ***
Input from the user
    Add heading    Type in the orders file loaction
    Add text input    url
    ${dialog}=    Run dialog
    RETURN    ${dialog}

Download the orders file
    [Arguments]    ${url}
    Download    ${url}    overwrite=True

Open the robot order website
    ${secret}=    Get Secret    rsb_url
    Open Available Browser    ${secret}[url]

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Element    css=#id-body-${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    Click Button    Order
    Wait Until Page Contains Element    css:div[id=order-completion]

Store the receipt as a PDF file
    [Arguments]    ${Order_number}
    Wait Until Element Is Visible    id:receipt
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${order_receipt_path}=    Set Variable    ${OUTPUT_DIR}${/}order_pdfs${/}${Order_number}.pdf
    Html To Pdf    ${order_receipt_html}    ${order_receipt_path}
    RETURN    ${order_receipt_path}

Take a screenshot of the robot
    [Arguments]    ${Order_number}
    ${screenshot_path}=    Set Variable    ${OUTPUT_DIR}${/}${Order_number}.png
    Screenshot    id:robot-preview-image    ${screenshot_path}
    RETURN    ${screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    @{images}=    Create List    ${screenshot}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf

Go to order another robot
    Click Button    Order another robot

Close the browser
    Close Browser

Create a ZIP file of the receipts
    ${output_pdfs_path}=    Set Variable    ${OUTPUT_DIR}${/}order_pdfs${/}
    Archive Folder With Zip    ${output_pdfs_path}    ${OUTPUT_DIR}${/}orders.zip
