---
layout: post
title: "excel导出工具类"
date: 2013-01-01 00:32:42 -0800
comments: true
categories: java code
keywords: 
tags: excel poi
description: 
---
前端使用jquery easyui，datagrid添加导出按钮（另外的js逻辑）即可将当前页或所有页数据(支持查询条件的导出)导出到excel，支持office excel 2003和2007+;  
使用apache poi（+ooxml）实现，主要代码片段如下：  
<!--more-->
```java
package com.colalife.core.util.excel;

public class ExcelExportUtil {
    private static Logger logger = LoggerFactory.getLogger(ExcelExportUtil.class);
	private static Map<String, CellStyle> styles;
	/**
	 * sheetName Excel导出文档里的标签页名，默认为Sheet1
	 */
	public static final String DEFAULT_SHEET_NAME = "Sheet1";
	/**
	 * excel导出时文件名，默认为"导出excel.xls"
	 */
	public static final String DEFAULT_EXCEL_FILE_NAME = "导出excel.xls";

	/**
	 * Excel导出,sheetName默认为Sheet1
	 * @param dataList 数据，可用bean list
	 * @param columns 字段和字段显示名的键值对
	 */
	public static void export(List<?> dataList, Map<String, String> columns, HttpServletResponse response)
			throws IOException {
		String[] fields = columns.keySet().toArray(new String[0]);
		String[] titles = columns.values().toArray(new String[0]);
		export(dataList, fields, titles, response);
	}

	/**
	 * Excel导出,sheetName默认为Sheet1
	 * @param dataList 数据，可用bean list
	 * @param EasyuiDataGrid 用来获取fields titles 字段和字段显示名的数组
	 */
	public static void export(List<?> dataList, EasyuiDataGrid dg, HttpServletResponse response)
			throws IOException {
		String[] fields = dg.getFields().split(",");
		String[] titles = dg.getTitles().split(",");
		Workbook excel = ExcelExportUtil.getExcel(dataList, fields, titles);
		ExcelExportUtil.setResponseForExcel(response);
		excel.write(response.getOutputStream());
		response.getOutputStream().flush();
		response.getOutputStream().close();
	}

	/**
	 * Excel导出,sheetName默认为Sheet1
	 * @param dataList 数据，可用bean list
	 * @param fields titles 字段和字段显示名的数组
	 */
	public static void export(List<?> dataList, String[] fields, String[] titles, HttpServletResponse response)
			throws IOException {
		Workbook excel = ExcelExportUtil.getExcel(dataList, fields, titles);
		ExcelExportUtil.setResponseForExcel(response);
		excel.write(response.getOutputStream());
		response.getOutputStream().flush();
		response.getOutputStream().close();
	}

	/**
	 * Excel导出的实现,sheetName默认为Sheet1
	 * @param data 数据，可用bean list
	 * @param columns 字段和字段显示名的键值对
	 */
	public static Workbook getExcel(List<?> data, Map<String, String> columns) {
		return getExcel(data, DEFAULT_SHEET_NAME, columns);
	}

	/**
	 * Excel导出的实现,sheetName默认为Sheet1
	 * @param data 数据，可用bean list
	 * @param columns 字段和字段显示名的键值对
	 */
	public static Workbook getExcel(List<?> data, String[] fields, String[] titles) {
		return getExcel(data, DEFAULT_SHEET_NAME, fields, titles);
	}

	/**
	 * Excel导出的实现
	 * @param data 数据，可用bean list
	 * @param sheetName 导出文档里的标签页名
	 * @param columns 字段和字段显示名的键值对
	 */
	public static Workbook getExcel(List<?> data, String sheetName, Map<String, String> columns) {
		String[] fields = columns.keySet().toArray(new String[0]);
		String[] titles = columns.values().toArray(new String[0]);
		return getExcel(data, sheetName, fields, titles);
	}

	/**
	 * Excel导出的实现
	 * @param data 数据，可用bean list
	 * @param sheetName 导出文档里的标签页名
	 * @param fields titles 字段和字段显示名的数组
	 */
	public static Workbook getExcel(List<?> data, String sheetName, String[] fields, String[] titles) {
		Workbook workbook = new HSSFWorkbook();
		//创建所有Cell Style
		createStyles(workbook);
		Sheet sheet = workbook.createSheet(sheetName);
		// 创建第一行,为excel表头
		Row row = sheet.createRow(0);
		// 序号列
		Cell numHeader = row.createCell(0);
		numHeader.setCellValue(new HSSFRichTextString("序号"));
		numHeader.setCellStyle(styles.get("header"));
		for (int i = 1; i <= titles.length; i++) {
			Cell header = row.createCell(i);
			header.setCellValue(new HSSFRichTextString(titles[i - 1]));
			header.setCellStyle(styles.get("header"));
		}
		// 创建其他各数据行
		if (!data.isEmpty()) {
			for (int j = 0; j < data.size(); j++) {
				Object bean = data.get(j);
				Row dataRow = sheet.createRow(j + 1);
				// 序号列
				Cell num = dataRow.createCell(0);
				num.setCellValue(new HSSFRichTextString(String.valueOf(j + 1)));
				num.setCellStyle(styles.get("normal"));
				for (int k = 1; k <= fields.length; k++) {
					Cell cell = dataRow.createCell(k);
					Object value = null;
					boolean isDate = false;
					try {
						value = PropertyUtils.getSimpleProperty(bean, fields[k - 1]);
						if (value instanceof Date) {
							value = DateUtil.formatDate((Date) value);
							isDate = true;
						}
					} catch (Exception e) {
						logger.error("Excel导出，获取属性值异常：" + e.getMessage());
					}
					HSSFRichTextString cellValue = new HSSFRichTextString(ObjectUtils.toString(value));
					cell.setCellValue(cellValue);
					cell.setCellStyle(isDate ? styles.get("dateCell") : styles.get("normal"));
				}
			}
		}
		for (int i = 0; i < titles.length; i++) {
			// 自适应宽度
			sheet.autoSizeColumn(i);
		}
		return workbook;
	}

	/**
	 * excel导出时用到的方法，直接调用
	 */
	public static void setResponseForExcel(HttpServletResponse response) {
		setResponseForExcel(response, DEFAULT_EXCEL_FILE_NAME);
	}

	/**
	 * excel导出时用到的方法，直接调用
	 * @throws UnsupportedEncodingException
	 */
	public static void setResponseForExcel(HttpServletResponse response, String fileName) {
		response.setContentType("application/vnd.ms-excel;charset=UTF-8");
		try {
			// 解决excel文件乱码问题
			response.setHeader("Content-Disposition", "attachment;filename="
					+ new String(fileName.getBytes("GB2312"), "ISO8859-1"));
		} catch (UnsupportedEncodingException e) {
			logger.error("Excel导出，转码异常：" + e.getMessage());
		}
		response.setHeader("Cache-Control", "must-revalidate, post-check=0, pre-check=0");
		response.setHeader("Pragma", "public");
		response.setDateHeader("Expires", 0);
	}

	private static Map<String, CellStyle> createStyles(Workbook wb) {
		styles = Maps.newHashMap();
		DataFormat df = wb.createDataFormat();

		// --字体设定 --//

		//普通字体
		Font normalFont = wb.createFont();
		normalFont.setFontName("宋体");
		normalFont.setFontHeightInPoints((short) 12);

		//加粗字体
		Font boldFont = wb.createFont();
		boldFont.setFontHeightInPoints((short) 12);
		boldFont.setBoldweight(Font.BOLDWEIGHT_BOLD);

		//蓝色加粗字体
		Font blueBoldFont = wb.createFont();
		blueBoldFont.setFontHeightInPoints((short) 12);
		blueBoldFont.setBoldweight(Font.BOLDWEIGHT_BOLD);
		blueBoldFont.setColor(IndexedColors.BLUE.getIndex());

		// --Cell Style设定-- //
		//普通格式
		CellStyle normalStyle = wb.createCellStyle();
		normalStyle.setFont(normalFont);
		styles.put("normal", normalStyle);

		//标题格式
		CellStyle headerStyle = wb.createCellStyle();
		headerStyle.setFont(boldFont);
		// 指定单元格居中对齐
		headerStyle.setAlignment(HSSFCellStyle.ALIGN_CENTER);
        // 指定单元格垂直居中对齐
		headerStyle.setVerticalAlignment(HSSFCellStyle.VERTICAL_CENTER);
		styles.put("header", headerStyle);

		//日期格式
		CellStyle dateCellStyle = wb.createCellStyle();
		dateCellStyle.setFont(normalFont);
		dateCellStyle.setDataFormat(df.getFormat("yyyy-MM-dd HH:mm:ss"));
//		setBorder(dateCellStyle);
		styles.put("dateCell", dateCellStyle);

		//数字格式
		CellStyle numberCellStyle = wb.createCellStyle();
		numberCellStyle.setFont(normalFont);
		numberCellStyle.setDataFormat(df.getFormat("#,##0.00"));
		setBorder(numberCellStyle);
		styles.put("numberCell", numberCellStyle);

		//合计列格式
		CellStyle totalStyle = wb.createCellStyle();
		totalStyle.setFont(blueBoldFont);
		totalStyle.setWrapText(true);
		totalStyle.setAlignment(CellStyle.ALIGN_RIGHT);
		setBorder(totalStyle);
		styles.put("total", totalStyle);

		return styles;
	}

	private static void setBorder(CellStyle style) {
		//设置边框
		style.setBorderRight(CellStyle.BORDER_THIN);
		style.setRightBorderColor(IndexedColors.BLACK.getIndex());

		style.setBorderLeft(CellStyle.BORDER_THIN);
		style.setLeftBorderColor(IndexedColors.BLACK.getIndex());

		style.setBorderTop(CellStyle.BORDER_THIN);
		style.setTopBorderColor(IndexedColors.BLACK.getIndex());

		style.setBorderBottom(CellStyle.BORDER_THIN);
		style.setBottomBorderColor(IndexedColors.BLACK.getIndex());
	}

}

```  
页面调用  
----
在相应页面的toolbar里添加导出按钮，调用js function，例如：  
```javascript
    function exportData() {
//		默认导出
//		jsUtil.doDefaultExport('<%=request.getContextPath()%>/core/operlog/export', datagrid);

// 		支持查询条件的导出
		var inputs = $("#searchForm input").clone();
		jsUtil.doExport('<%=request.getContextPath()%>/core/operlog/export', datagrid, inputs);
	}

```
jsUtil里的js逻辑：  
```javascript
/**
 * 提交导出form
 */
jsUtil.submitExportForm = function(form) {
    form.submit();
	form.remove();
}
/**
 * 导出方法，input为其他查询条件
 */
jsUtil.doExport = function(url, dg, inputs) {
	$.messager.defaults = { ok:"当前页数据", cancel:"所有页数据" };
	//导出当前页的数据?导出符合条件的所有数据?
	$.messager.confirm('导出', '选择导出查询结果里的：', function(isCurrent){
		var form = jsUtil.getDefaultExportForm(url, dg, isCurrent);
		if (inputs != null) {
			// 其他查询条件
			for (var i = 0; i < inputs.length; i++) {
				form.append(inputs[i]);
			}
		}
		jsUtil.submitExportForm(form);
	});
	$.messager.defaults = { ok:"确定", cancel:"取消" };
}
/**
 * 导出方法，无其他附加条件，按后台逻辑导出数据
 */
jsUtil.doDefaultExport = function(url, dg) {
	 var form = jsUtil.getDefaultExportForm(url, dg);
	 jsUtil.submitExportForm(form);
}
/**
 * 构造导出form，默认提交分页信息，列表字段和字段显示名信息
 */
jsUtil.getDefaultExportForm = function(url, dg, isCurrent) {
	var form = $("<form>");
	form.attr('style', 'display:none');
	form.attr('target', '');
	form.attr('method', 'post');
	form.attr('action', url);
	$('body').append(form);
	var defaultInputs = jsUtil.getDefaultInputs(url, dg, isCurrent);
	for (var i = 0; i < defaultInputs.length; i++) {
		form.append(defaultInputs[i]);
	}
	return form;
}
/**
 * 导出form的默认提交参数，包括分页信息，列表字段和字段显示名信息
 */
jsUtil.getDefaultInputs = function(url, dg, isCurrent) {
	var inputs = [];
	var page = $('<input>');
	page.attr('type', 'hidden');
	page.attr('name', 'page');
	var rows = $('<input>');
	rows.attr('type', 'hidden');
	rows.attr('name', 'rows');
	//导出当前页的数据?导出符合条件的所有数据?
	if (isCurrent) {
		page.attr('value', dg.datagrid('options').pageNumber);
		rows.attr('value', dg.datagrid("options").pageSize);
	} else {
		page.attr('value', 1);
		rows.attr('value', 2147483647);
	}

	var sort = $('<input>');
	sort.attr('type', 'hidden');
	sort.attr('name', 'sort');
	sort.attr('value', dg.datagrid('options').sortName);

	var order = $('<input>');
	order.attr('type', 'hidden');
	order.attr('name', 'order');
	order.attr('value', dg.datagrid('options').sortOrder);

	var fields = $('<input>');
	fields.attr('type', 'hidden');
	fields.attr('name', 'fields');
	fields.attr('value', jsUtil.getFields(dg));

	var titles = $('<input>');
	titles.attr('type', 'hidden');
	titles.attr('name', 'titles');
	titles.attr('value', jsUtil.getTitles(dg));

	inputs.push(page);
	inputs.push(rows);
	inputs.push(sort);
	inputs.push(order);
	inputs.push(fields);
	inputs.push(titles);
	return inputs;
};
/**
 * 导出form的列表字段
 */
jsUtil.getFields = function(dg) {
	var columns = dg.datagrid("options").columns[0];
	var json = '';
	if (columns) {
		for (var i = 0; i < columns.length; i++) {
			var field = columns[i].field;
			var title = columns[i].title;
			var hidden = columns[i].hidden;
			if (!hidden) {
				json += field + ','
			}
		}
		if (json != '') {
			json = json.substring(0, json.length - 1);
		}
	}
	return json;
};
/**
 * 导出form的列表字段显示名称
 */
jsUtil.getTitles = function(dg) {
	var columns = dg.datagrid("options").columns[0];
	var json = '';
	if (columns) {
		for (var i = 0; i < columns.length; i++) {
			var field = columns[i].field;
			var title = columns[i].title;
			var hidden = columns[i].hidden;
			if (!hidden) {
				json += title + ','
			}
		}
		if (json != '') {
			json = json.substring(0, json.length - 1);
		}
	}
	return json;
};



```
