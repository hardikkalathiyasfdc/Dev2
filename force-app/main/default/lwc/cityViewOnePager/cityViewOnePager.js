import { loadScript } from 'lightning/platformResourceLoader';
import docxImport from '@salesforce/resourceUrl/JSWord';
import cityViewImage from '@salesforce/resourceUrl/CityViewOnePagerLogo';

let isScriptLoaded = false;
let docxLib = null;

async function ensureScriptLoaded(componentInstance) {
    if (isScriptLoaded) {
        return;
    }

    try {
        await loadScript(componentInstance, docxImport + '/index.js');
        isScriptLoaded = true;

        if (window.docx) {
            docxLib = window.docx;
        } else {
            throw new Error('docx library not found after script load.');
        }
    } catch (error) {
        console.error('Error loading docx script:', error);
    }
}

export async function generateDocument(componentInstance, data) {
    if (!data.selectedMapMarker) {
        console.error('Invalid geoAreaId provided');
        return;
    }

    await ensureScriptLoaded(componentInstance);

    try {
        const logoBase64 = await fetchBase64FromUrl(cityViewImage);
        buildDocument(data, logoBase64);
    } catch (error) {
        console.error('Failed to load image for header:', error);
        buildDocument(data, null);
    }
}

function buildDocument(data, logoBase64) {
    if (!docxLib) {
        console.error('docx library is not loaded.');
        return;
    }

    const {
        selectedMapMarker,
        mayors,
        cityData,
        offices,
        culturalAccess,
        highlights,
        events,
        userName,
        isCountrySelected,
        isStateSelected,
        cityLevelWorkCountryData,
        selectedGroupByForStateOnCountryLevel,
        selectedGroupByForCityOnCountryLevel,
        keyPartners,
        addDescription,
        cityViewCountryLevelWorkData
    } = data;

    const documentChildren = [];
    documentChildren.push(new docxLib.Paragraph({ text: "", spacing: { after: 100 } }));

    if (mayors?.length && !isCountrySelected) {
        documentChildren.push(createMayorTable(mayors));
        documentChildren.push(new docxLib.Paragraph({ text: "", spacing: { after: 100 } }));
    }

    if (cityData?.groupedCityWork?.length && !isCountrySelected && !isStateSelected) {
        documentChildren.push(...createCityLevelWorkSection(cityData.groupedCityWork, 'City Level Work', cityData.shallShowGrants, addDescription));
        const groupedStateWork = groupByFocusArea(cityData.stateWork);
        if (groupedStateWork.length) {
            documentChildren.push(...createCityLevelWorkSection(groupedStateWork, 'State Level Work', cityData.shallShowGrants, addDescription));
        }
    }

    if (cityData?.showStateFlag && cityData?.stateWork?.length && isStateSelected) {
        const groupedStateWork = groupByFocusArea(cityData.stateWork);
        if (groupedStateWork.length) {
            documentChildren.push(...createCityLevelWorkSection(groupedStateWork, 'State Level Work', cityData.shallShowGrants, addDescription));
        }
    }
    if (cityData?.countryWork?.length) {
        const groupedCountryWork = groupByFocusArea(cityData.countryWork);
        if (groupedCountryWork.length) {
            documentChildren.push(...createCityLevelWorkSection(groupedCountryWork, 'Country Level Work', cityData.shallShowGrants, addDescription));
        }
    }

    if (cityData?.showStateFlag && cityData?.stateWork?.length && isCountrySelected) {
        documentChildren.push(...createCityLevelWorkCountry(cityViewCountryLevelWorkData.data, 'State Level Work', cityViewCountryLevelWorkData.shallShowGrants, addDescription, selectedGroupByForStateOnCountryLevel));

    }
    if (cityLevelWorkCountryData.data?.length && isCountrySelected || isStateSelected) {
        documentChildren.push(...createCityLevelWorkCountry(cityLevelWorkCountryData.data, 'City Level Work', cityLevelWorkCountryData.shallShowGrants, addDescription, selectedGroupByForCityOnCountryLevel));
    }

    let partnerHeaderTitle = isCountrySelected ? 'Country Level Partners' : isStateSelected ? 'State Level Partners' : 'City Level Partners';
    createKeyPartnerTable
    if (keyPartners?.length) {
        documentChildren.push(...createKeyPartnerTable(keyPartners, partnerHeaderTitle));
    }

    if (events?.length) {
        documentChildren.push(...createEventsSection(events));
    }

    if (culturalAccess?.length) {
        if (isCountrySelected || isStateSelected) {
            documentChildren.push(...createCulturalAccessSection(culturalAccess));
        }
        else {
            documentChildren.push(...createCulturalAccessSection2(culturalAccess));
        }
    }

    if (offices?.length) {
        documentChildren.push(...createOfficesSection(offices));
    }
    let highlightsData = highlights?.rawData;
    let headerTitle = isCountrySelected ? 'Country Level Highlights ' : isStateSelected ? 'State Level Highlights ' : 'City Level Highlights ';
    headerTitle = headerTitle + '(' + highlights?.highlightTitle + ')';
    if (highlightsData?.length && isCountrySelected) {
        documentChildren.push(...createHighlightsSection(highlightsData, headerTitle));
    }

    if (highlightsData?.length && !isCountrySelected) {
        documentChildren.push(...createHighlightsSection(highlightsData, headerTitle));
    }

    const wordDocument = new docxLib.Document({
        styles: {
            default: {
                document: {
                    run: {
                        font: "Arial",
                        size: 22,
                    },
                    paragraph: {
                        spacing: { after: 120 },
                    },
                },
            },
            paragraphStyles: [
                {
                    id: "Normal",
                    name: "Normal",
                    run: { font: "Arial", size: 22, color: "000000" },
                    paragraph: { spacing: { after: 120 } }
                },
                {
                    id: "Heading1",
                    name: "Heading 1",
                    basedOn: "Normal",
                    next: "Normal",
                    quickFormat: true,
                    run: { font: "Arial", size: 48, bold: true, color: "000000" },
                    paragraph: { spacing: { after: 300 } }
                }
            ]
        }
    });

    let title = (selectedMapMarker.name ? selectedMapMarker.name : selectedMapMarker.title);
    wordDocument.addSection({
        headers: {
            default: createHeaderSection(wordDocument, logoBase64, title)
        },
        footers: {
            default: pageFooter(userName)
        },
        children: documentChildren
    });

    docxLib.Packer.toBase64String(wordDocument).then(textBlob => {
        const downloadURL = 'data:application/vnd.openxmlformats-officedocument.wordprocessingml.document;base64,' + textBlob;
        const linkElement = window.document.createElement('a');
        linkElement.href = downloadURL;
        linkElement.download = `City View 1-Pager ${title}.docx`;
        window.document.body.appendChild(linkElement);
        linkElement.click();
        window.document.body.removeChild(linkElement);
    }).catch(error => {
        console.error("Error generating the document:", error);
    });
}

function createMayorTable(mayors) {
    const mergedHeaderRow = new docxLib.TableRow({
        children: [
            new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        children: [
                            new docxLib.TextRun({
                                text: "Recent Mayors",
                                bold: true,
                                color: "FFFFFF",
                                size: 22,
                            })
                        ],
                        alignment: docxLib.AlignmentType.LEFT,
                        style: "Normal",
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                columnSpan: 2,
                shading: { fill: "2795be" },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                }
            })
        ]
    });

    const tableRows = mayors.map(mayor => {
        const contactName = mayor.Contact_Name__r?.Name || mayor.Contact_Name__c || '';
        const from = mayor.From__c || '';
        const to = mayor.To__c || 'Present';
        const term = `${from} - ${to}`;

        return new docxLib.TableRow({
            children: [
                new docxLib.TableCell({
                    children: [
                        new docxLib.Paragraph({
                            text: contactName,
                            style: "Normal",
                            spacing: { before: 20, after: 20 },
                            indent: { left: 100 }
                        })
                    ],
                    verticalAlign: docxLib.VerticalAlign.CENTER,
                    margins: { top: 20, bottom: 20, left: 20, right: 20 },
                    width: { size: 70, type: docxLib.WidthType.PERCENTAGE },
                    borders: {
                        top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                    }
                }),
                new docxLib.TableCell({
                    children: [
                        new docxLib.Paragraph({
                            text: term,
                            style: "Normal",
                            spacing: { before: 20, after: 20 },
                            indent: { left: 100 }
                        })
                    ],
                    verticalAlign: docxLib.VerticalAlign.CENTER,
                    margins: { top: 20, bottom: 20, left: 20, right: 20 },
                    width: { size: 30, type: docxLib.WidthType.PERCENTAGE },
                    borders: {
                        top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                    }
                }),
            ]
        });
    });

    return new docxLib.Table({
        rows: [mergedHeaderRow, ...tableRows],
        width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
    });
}

function createCityLevelWorkSection(cityLevelWork, sectionName, shallShowGrants, addDescription) {
    const section = [];

    const mergedHeaderRow = new docxLib.TableRow({
        children: [
            new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        children: [
                            new docxLib.TextRun({
                                text: sectionName,
                                bold: true,
                                color: "FFFFFF",
                                size: 22
                            })
                        ],
                        alignment: docxLib.AlignmentType.LEFT,
                        style: "Normal",
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                columnSpan: 3,
                shading: { fill: "2795be" },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                }
            })
        ]
    });

    section.push(new docxLib.Table({
        rows: [mergedHeaderRow],
        width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
    }));

    cityLevelWork.forEach((focus, index) => {
        const fontColor = focus.color?.replace('#', '');

        function createColorCell() {
            return new docxLib.TableCell({
                children: [new docxLib.Paragraph({ text: " " })],
                width: { size: 1, type: docxLib.WidthType.PERCENTAGE },
                shading: { fill: fontColor },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: fontColor },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: fontColor },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: fontColor },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: fontColor }
                },
                margins: { top: 20, bottom: 20, left: 20, right: 20 }
            });
        }

        function createNormalCell(text, widthPercentage, isSecondColumn = false) {
            return new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        text,
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                width: { size: widthPercentage, type: docxLib.WidthType.PERCENTAGE },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: {
                        style: docxLib.BorderStyle.SINGLE,
                        size: 2,
                        color: isSecondColumn ? fontColor : "000000"
                    },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                },
                margins: { top: 20, bottom: 20, left: 20, right: 20 }
            });
        }

        const headerRow = new docxLib.TableRow({
            children: [
                createColorCell(),
                new docxLib.TableCell({
                    children: [
                        new docxLib.Paragraph({
                            children: [
                                new docxLib.TextRun({
                                    text: focus.focusArea,
                                    bold: true,
                                    color: "000000",
                                    size: 22,
                                })
                            ],
                            alignment: docxLib.AlignmentType.LEFT,
                            style: "Normal",
                            spacing: { before: 20, after: 20 },
                            indent: { left: 100 }
                        })
                    ],
                    columnSpan: 2,
                    shading: { fill: "deeaf6" },
                    width: { size: 99, type: docxLib.WidthType.PERCENTAGE },
                    verticalAlign: docxLib.VerticalAlign.CENTER,
                    borders: {
                        top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: fontColor },
                        right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                    },
                    margins: { top: 20, bottom: 20, left: 20, right: 20 }
                })
            ]
        });

        let tableRows = [];
        focus.records.forEach(record => {
            let name =  record.associationName || '';
            const from = record.startDate || '';
            const to = record.endDate || 'Present';
            let term = `${from} - ${to}`;

            if (!record.showDate) {
                term = "N/A";
            }
            if (record.nonConsecutive) {
                term = term + ' (Non-Consecutive)'
            }
            tableRows.push(
                new docxLib.TableRow({
                    children: [
                        createColorCell(),
                        createNormalCell(name, 69, true),
                        createNormalCell(term, 30)
                    ]
                })
            );
            if(addDescription) {
                let descriptionText = record.description || '';
                tableRows.push( 
                    new docxLib.TableRow({
                        children: [
                            createColorCell(),
                            createNormalCell(descriptionText, 69, true),
                            createNormalCell('', 30)
                        ]
                    })
                );
            }
        });

        const table = new docxLib.Table({
            rows: [headerRow, ...tableRows],
            width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
        });

        section.push(table);

        if (index === cityLevelWork.length - 1) {
            section.push(new docxLib.Paragraph({ text: "", spacing: { after: 100 } }));
        }
    });

    return section;
}


function createOfficesSection(offices) {
    if (!offices || offices.length === 0) {
        return [];
    }

    const section = [];

    const headerRow = new docxLib.TableRow({
        children: [
            new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        children: [
                            new docxLib.TextRun({
                                text: "Bloomberg Offices",
                                bold: true,
                                color: "FFFFFF",
                                size: 22
                            })
                        ],
                        alignment: docxLib.AlignmentType.LEFT,
                        style: "Normal",
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                shading: { fill: "2795be" },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                }
            })
        ]
    });

    const tableRows = offices.map(office => {
        return new docxLib.TableRow({
            children: [
                new docxLib.TableCell({
                    children: [
                        new docxLib.Paragraph({
                            text: office.addressText || '',
                            style: "Normal",
                            spacing: { before: 20, after: 20 },
                            indent: { left: 100 }
                        })
                    ],
                    verticalAlign: docxLib.VerticalAlign.CENTER,
                    margins: { top: 20, bottom: 20, left: 20, right: 20 },
                    borders: {
                        top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                    }
                })
            ]
        });
    });

    section.push(
        new docxLib.Table({
            rows: [headerRow, ...tableRows],
            width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
        }),
        new docxLib.Paragraph({ text: "", spacing: { after: 200 } })
    );

    return section;
}

function createKeyPartnerTable(keyPartners, headerTitle) {
    if (!keyPartners || keyPartners.length === 0) {
        return [];
    }

    const section = [];

    const headerRow = new docxLib.TableRow({
        children: [
            new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        children: [
                            new docxLib.TextRun({
                                text: headerTitle,
                                bold: true,
                                color: "FFFFFF",
                                size: 22
                            })
                        ],
                        alignment: docxLib.AlignmentType.LEFT,
                        style: "Normal",
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                shading: { fill: "2795be" },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                }
            })
        ]
    });

    const tableRows = keyPartners.map(item => {
        return new docxLib.TableRow({
            children: [
                new docxLib.TableCell({
                    children: [
                        new docxLib.Paragraph({
                            text: item.Organization__r.Name || '',
                            style: "Normal",
                            spacing: { before: 20, after: 20 },
                            indent: { left: 100 }
                        })
                    ],
                    verticalAlign: docxLib.VerticalAlign.CENTER,
                    margins: { top: 20, bottom: 20, left: 20, right: 20 },
                    borders: {
                        top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                    }
                })
            ]
        });
    });

    section.push(
        new docxLib.Table({
            rows: [headerRow, ...tableRows],
            width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
        }),
        new docxLib.Paragraph({ text: "", spacing: { after: 200 } })
    );

    return section;
}

function createCulturalAccessSection2(culturalAccessData) {
    if (!culturalAccessData || culturalAccessData.length === 0) {
        return [];
    }

    const section = [];

    const headerRow = new docxLib.TableRow({
        children: [
            new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        children: [
                            new docxLib.TextRun({
                                text: "Cultural Access",
                                bold: true,
                                color: "FFFFFF",
                                size: 22
                            })
                        ],
                        alignment: docxLib.AlignmentType.LEFT,
                        style: "Normal",
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                shading: { fill: "2795be" },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                }
            })
        ]
    });

    const tableRows = culturalAccessData.map(item => {
        return new docxLib.TableRow({
            children: [
                new docxLib.TableCell({
                    children: [
                        new docxLib.Paragraph({
                            text: item.organizationName || '',
                            style: "Normal",
                            spacing: { before: 20, after: 20 },
                            indent: { left: 100 }
                        })
                    ],
                    verticalAlign: docxLib.VerticalAlign.CENTER,
                    margins: { top: 20, bottom: 20, left: 20, right: 20 },
                    borders: {
                        top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                    }
                })
            ]
        });
    });

    section.push(
        new docxLib.Table({
            rows: [headerRow, ...tableRows],
            width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
        }),
        new docxLib.Paragraph({ text: "", spacing: { after: 200 } })
    );

    return section;
}

function createCulturalAccessSection(culturalAccessData) {
    const section = [];

    const mergedHeaderRow = new docxLib.TableRow({
        children: [
            new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        children: [
                            new docxLib.TextRun({
                                text: "Cultural Access",
                                bold: true,
                                color: "FFFFFF",
                                size: 22
                            })
                        ],
                        alignment: docxLib.AlignmentType.LEFT,
                        style: "Normal",
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                shading: { fill: "2795be" },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                }
            })
        ]
    });

    section.push(new docxLib.Table({
        rows: [mergedHeaderRow],
        width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
    }));

    culturalAccessData.forEach((city, index) => {

        function createColorCell() {
            return new docxLib.TableCell({
                children: [new docxLib.Paragraph({ text: " " })],
                width: { size: 1, type: docxLib.WidthType.PERCENTAGE },
                shading: {},
                margins: { top: 20, bottom: 20, left: 20, right: 20 }
            });
        }

        function createNormalCell(text, widthPercentage, isSecondColumn = false) {
            return new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        text,
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                width: { size: widthPercentage, type: docxLib.WidthType.PERCENTAGE },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 }
            });
        }

        const headerRow = new docxLib.TableRow({
            children: [
                new docxLib.TableCell({
                    children: [
                        new docxLib.Paragraph({
                            children: [
                                new docxLib.TextRun({
                                    text: city.name,
                                    bold: true,
                                    color: "000000",
                                    size: 22,
                                })
                            ],
                            alignment: docxLib.AlignmentType.LEFT,
                            style: "Normal",
                            spacing: { before: 20, after: 20 },
                            indent: { left: 100 }
                        })
                    ],
                    shading: { fill: "deeaf6" },
                    width: { size: 99, type: docxLib.WidthType.PERCENTAGE },
                    verticalAlign: docxLib.VerticalAlign.CENTER,
                    margins: { top: 20, bottom: 20, left: 20, right: 20 }
                })
            ]
        });

        const tableRows = city.rows?.map(record => {
            const name = record.organizationName || '';
            return new docxLib.TableRow({
                children: [
                    createNormalCell(name, 69, true),
                ]
            });
        });

        const table = new docxLib.Table({
            rows: [headerRow, ...tableRows],
            width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
        });

        section.push(table);

        if (index === culturalAccessData.length - 1) {
            section.push(new docxLib.Paragraph({ text: "", spacing: { after: 100 } }));
        }
    });

    return section;
}

function createCityLevelWorkCountry(cityLevelWorkCountryData, sectionName, shallShowGrants, addDescription, selectedGroupBy) {
    if (!cityLevelWorkCountryData || cityLevelWorkCountryData.length === 0) {
        return [];
    }

    const section = [];

    const headerRow = new docxLib.TableRow({
        children: [
            new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        children: [
                            new docxLib.TextRun({
                                text: sectionName,
                                bold: true,
                                color: "FFFFFF",
                                size: 22
                            })
                        ],
                        alignment: docxLib.AlignmentType.LEFT,
                        style: "Normal",
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                shading: { fill: "2795be" },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                }
            })
        ]
    });

    let tableRows = [];
    cityLevelWorkCountryData.forEach(item => {
        tableRows.push(
            new docxLib.TableRow({
                children: [
                    new docxLib.TableCell({
                        children: [
                            new docxLib.Paragraph({
                                children: [
                                    new docxLib.TextRun({
                                        text: item.displayName || '',
                                        bold: item.customCss == "boldfontcss" ? true : false
                                    })
                                ],
                                style: "Normal",
                                spacing: { before: 20, after: 20 },
                                indent: { left: 100 }
                            })
                        ],
                        verticalAlign: docxLib.VerticalAlign.CENTER,
                        margins: { top: 20, bottom: 20, left: 20, right: 20 },
                        borders: {
                            top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                            bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                            left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                            right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                        }
                    })
                ]
            })
        );
        if(addDescription && (selectedGroupBy != 'city')) {
            tableRows.push(
                new docxLib.TableRow({
                    children: [
                        new docxLib.TableCell({
                            children: [
                                new docxLib.Paragraph({
                                    children: [
                                        new docxLib.TextRun({
                                            text:  item.associationData.description || '',
                                        })
                                    ],
                                    style: "Normal",
                                    spacing: { before: 20, after: 20 },
                                    indent: { left: 100 }
                                })
                            ],
                            verticalAlign: docxLib.VerticalAlign.CENTER,
                            margins: { top: 20, bottom: 20, left: 20, right: 20 },
                            borders: {
                                top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                                bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                                left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                                right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                            }
                        })
                    ]
                })
            );
        }
    });

    section.push(
        new docxLib.Table({
            rows: [headerRow, ...tableRows],
            width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
        }),
        new docxLib.Paragraph({ text: "", spacing: { after: 200 } })
    );

    return section;
}

function createHighlightsSection(highlights, headerTitle) {
    const grouped = groupHighlightsByMonth(highlights);
    const section = createHighlightsSectionGrouped(grouped, headerTitle);
    return section;
}

function groupHighlightsByMonth(highlights) {
    const grouped = {};

    highlights.forEach(item => {
        const rawDate = item.Interaction_Date__c;
        let date = null;

        if (rawDate) {
            const parts = rawDate.split('-'); // ["2022", "07", "01"]
            date = new Date(parts[0], parts[1] - 1, parts[2]); // Safe local date
        }

        const monthYear = date.toLocaleString('default', { month: 'long', year: 'numeric' }); // e.g., "April 2024"

        if (!grouped[monthYear]) {
            grouped[monthYear] = [];
        }

        grouped[monthYear].push(item);
    });

    return grouped;
}

function createHighlightsSectionGrouped(groupedHighlights, headerTitle) {
    const monthKeys = Object.keys(groupedHighlights);
    if (monthKeys.length === 0) return [];

    const section = [];
    const headerRow = new docxLib.TableRow({
        children: [
            new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        children: [
                            new docxLib.TextRun({
                                text: headerTitle,
                                bold: true,
                                color: "FFFFFF",
                                size: 22
                            })
                        ],
                        alignment: docxLib.AlignmentType.LEFT,
                        style: "Normal",
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                columnSpan: 2,
                shading: { fill: "2795be" },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                }
            })
        ]
    });

    const tableRows = [];

    for (const month of monthKeys) {
        const items = groupedHighlights[month];

        const highlightParagraphs = [];

        items.forEach((item, index) => {
            const focus = item.FC_Focus_Area__c || '';
            const desc = item.Description__c || '';

            highlightParagraphs.push(
                new docxLib.Paragraph({
                    children: [
                        new docxLib.TextRun({ text: focus, bold: true }),
                        new docxLib.TextRun({ text: ` - ${desc}` })
                    ],
                    spacing: { before: 20, after: 0 },
                    indent: { left: 100 },
                    style: "Normal"
                })
            );
            if (index < items.length - 1) {
                highlightParagraphs.push(new docxLib.Paragraph({ text: "" }));
            }
        });

        tableRows.push(
            new docxLib.TableRow({
                children: [
                    new docxLib.TableCell({
                        children: [
                            new docxLib.Paragraph({
                                children: [
                                    new docxLib.TextRun({
                                        text: month,
                                        bold: true
                                    })
                                ],
                                spacing: { before: 20, after: 20 },
                                indent: { left: 100 },
                                style: "Normal"
                            })
                        ],
                        width: { size: 30, type: docxLib.WidthType.PERCENTAGE },
                        shading: { fill: "deeaf6" },
                        verticalAlign: docxLib.VerticalAlign.CENTER,
                        margins: { top: 20, bottom: 20, left: 20, right: 20 },
                        borders: {
                            top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                            bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                            left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                            right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                        }
                    }),
                    new docxLib.TableCell({
                        children: highlightParagraphs,
                        width: { size: 70, type: docxLib.WidthType.PERCENTAGE },
                        verticalAlign: docxLib.VerticalAlign.CENTER,
                        margins: { top: 20, bottom: 20, left: 20, right: 20 },
                        borders: {
                            top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                            bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                            left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                            right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                        }
                    })
                ]
            })
        );
    }

    section.push(
        new docxLib.Table({
            rows: [headerRow, ...tableRows],
            width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
        }),
        new docxLib.Paragraph({ text: "", spacing: { after: 200 } })
    );

    return section;
}

function createHeaderSection(doc, logoBase64, cityName) {
    const borderNone = {
        top: { style: docxLib.BorderStyle.NONE, size: 0, color: "FFFFFF" },
        bottom: { style: docxLib.BorderStyle.NONE, size: 0, color: "FFFFFF" },
        left: { style: docxLib.BorderStyle.NONE, size: 0, color: "FFFFFF" },
        right: { style: docxLib.BorderStyle.NONE, size: 0, color: "FFFFFF" },
        insideHorizontal: { style: docxLib.BorderStyle.NONE, size: 0, color: "FFFFFF" },
        insideVertical: { style: docxLib.BorderStyle.NONE, size: 0, color: "FFFFFF" }
    };

    let logoParagraph = [];

    if (logoBase64) {
        const byteArray = Uint8Array.from(atob(logoBase64), c => c.charCodeAt(0));
        const tmpImg = docxLib.Media.addImage(doc, byteArray, 140, 55);

        logoParagraph.push(
            new docxLib.Paragraph({
                children: [tmpImg],
                alignment: docxLib.AlignmentType.CENTER
            })
        );
    }

    return new docxLib.Header({
        children: [
            new docxLib.Table({
                rows: [
                    new docxLib.TableRow({
                        children: [
                            new docxLib.TableCell({
                                children: [
                                    new docxLib.Paragraph({
                                        children: [
                                            new docxLib.TextRun({
                                                text: cityName || '',
                                                bold: true,
                                                size: 30,
                                                color: "1F4E79"
                                            })
                                        ],
                                        alignment: docxLib.AlignmentType.LEFT,
                                        style: "Normal"
                                    })
                                ],
                                width: { size: 80, type: docxLib.WidthType.PERCENTAGE },
                                verticalAlign: docxLib.VerticalAlign.CENTER,
                                borders: borderNone,
                                margins: { top: 0, bottom: 0, left: 0, right: 0 }
                            }),
                            new docxLib.TableCell({
                                children: logoParagraph,
                                width: { size: 20, type: docxLib.WidthType.PERCENTAGE },
                                verticalAlign: docxLib.VerticalAlign.CENTER,
                                borders: borderNone,
                                margins: { top: 0, bottom: 0, left: 0, right: 0 },
                            })
                        ]
                    })
                ],
                width: { size: 100, type: docxLib.WidthType.PERCENTAGE },
                borders: borderNone
            }),
            new docxLib.Paragraph({
                text: "",
                spacing: { after: 0 }
            })
        ]
    });
}

function createEventsSection(events) {
    if (!events || events.length === 0) {
        return [];
    }

    const section = [];
    const now = new Date();

    const upcoming = events.filter(e => new Date(e.StartDateTime) >= now);
    const past = events.filter(e => new Date(e.StartDateTime) < now);

    const headerRow = new docxLib.TableRow({
        children: [
            new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        children: [
                            new docxLib.TextRun({
                                text: "Employee Travel",
                                bold: true,
                                color: "FFFFFF",
                                size: 22
                            })
                        ],
                        alignment: docxLib.AlignmentType.LEFT,
                        style: "Normal",
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                columnSpan: 2,
                shading: { fill: "2795be" },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                }
            })
        ]
    });

    const groupRow = label => new docxLib.TableRow({
        children: [
            new docxLib.TableCell({
                children: [
                    new docxLib.Paragraph({
                        children: [
                            new docxLib.TextRun({
                                text: label,
                                bold: true,
                                color: "000000",
                                size: 22
                            })
                        ],
                        style: "Normal",
                        spacing: { before: 20, after: 20 },
                        indent: { left: 100 }
                    })
                ],
                columnSpan: 2,
                shading: { fill: "deeaf6" },
                verticalAlign: docxLib.VerticalAlign.CENTER,
                margins: { top: 20, bottom: 20, left: 20, right: 20 },
                borders: {
                    top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                    right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                }
            })
        ]
    });

    const eventRow = (event) => {
        const start = event.formattedStartDate || '';
        const end = event.formattedEndDate;
        const timeDisplay = end ? `${start} - ${end}` : start;
        const contactNames = event.ContactNames || '';

        return new docxLib.TableRow({
            children: [
                new docxLib.TableCell({
                    children: [
                        new docxLib.Paragraph({
                            text: timeDisplay,
                            style: "Normal",
                            spacing: { before: 20, after: 20 },
                            indent: { left: 100 }
                        })
                    ],
                    width: { size: 40, type: docxLib.WidthType.PERCENTAGE },
                    verticalAlign: docxLib.VerticalAlign.CENTER,
                    margins: { top: 20, bottom: 20, left: 20, right: 20 },
                    borders: {
                        top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                    }
                }),
                new docxLib.TableCell({
                    children: [
                        new docxLib.Paragraph({
                            text: contactNames,
                            style: "Normal",
                            spacing: { before: 20, after: 20 },
                            indent: { left: 100 }
                        })
                    ],
                    width: { size: 60, type: docxLib.WidthType.PERCENTAGE },
                    verticalAlign: docxLib.VerticalAlign.CENTER,
                    margins: { top: 20, bottom: 20, left: 20, right: 20 },
                    borders: {
                        top: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        bottom: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        left: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" },
                        right: { style: docxLib.BorderStyle.SINGLE, size: 2, color: "000000" }
                    }
                })
            ]
        });
    };

    const rows = [headerRow];

    if (upcoming.length > 0) {
        rows.push(groupRow("Upcoming"));
        upcoming.forEach(e => rows.push(eventRow(e)));
    }

    if (past.length > 0) {
        rows.push(groupRow("Recent"));
        past.forEach(e => rows.push(eventRow(e)));
    }

    section.push(
        new docxLib.Table({
            rows,
            width: { size: 100, type: docxLib.WidthType.PERCENTAGE }
        }),
        new docxLib.Paragraph({ text: "", spacing: { after: 200 } })
    );

    return section;
}

function groupByFocusArea(data) {
    if (!Array.isArray(data)) return [];

    const map = new Map();

    data.forEach(item => {
        const key = item.focusArea;
        if (!map.has(key)) {
            map.set(key, {
                focusArea: key,
                color: item.color || "#000000",
                records: []
            });
        }
        map.get(key).records.push(item);
    });

    return Array.from(map.values());
}

function pageFooter(createdByUser) {
    const now = new Date();
    const createdDate = now.toLocaleString('en-US', {
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
    });

    const font = "Times New Roman";

    const footerTable = new docxLib.Table({
        rows: [
            new docxLib.TableRow({
                children: [
                    new docxLib.TableCell({
                        children: [
                            new docxLib.Paragraph({
                                alignment: docxLib.AlignmentType.LEFT,
                                children: [
                                    new docxLib.TextRun({
                                        text: `Created By ${createdByUser} (via BRM)`,
                                        font: font,
                                        size: 18
                                    }),
                                ],
                            }),
                            new docxLib.Paragraph({
                                alignment: docxLib.AlignmentType.LEFT,
                                children: [
                                    new docxLib.TextRun({
                                        text: `On ${createdDate}`,
                                        font: font,
                                        size: 18
                                    }),
                                ],
                            })
                        ],
                        borders: getNoBorders(),
                        width: { size: 50, type: docxLib.WidthType.PERCENTAGE }
                    }),
                    new docxLib.TableCell({
                        children: [
                            new docxLib.Paragraph({
                                alignment: docxLib.AlignmentType.RIGHT,
                                children: [
                                    new docxLib.TextRun({
                                        children: [
                                            docxLib.PageNumber.CURRENT,
                                            " of ",
                                            docxLib.PageNumber.TOTAL_PAGES
                                        ],
                                        font: font,
                                        size: 18
                                    })
                                ],
                            })
                        ],
                        borders: getNoBorders(),
                        width: { size: 50, type: docxLib.WidthType.PERCENTAGE }
                    })
                ]
            })
        ]
    });

    return new docxLib.Footer({
        children: [footerTable]
    });
}

function getNoBorders() {
    return {
        top: { style: docxLib.BorderStyle.NONE, size: 0, color: "FFFFFF" },
        bottom: { style: docxLib.BorderStyle.NONE, size: 0, color: "FFFFFF" },
        left: { style: docxLib.BorderStyle.NONE, size: 0, color: "FFFFFF" },
        right: { style: docxLib.BorderStyle.NONE, size: 0, color: "FFFFFF" },
    };
}

function fetchBase64FromUrl(url) {
    return fetch(url, { mode: 'no-cors' })
        .then(response => response.blob())
        .then(blob => new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64Data = reader.result;
                const base64 = base64Data.split(',')[1];
                resolve(base64);
            };
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        }));
}