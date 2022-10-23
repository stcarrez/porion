/*
 *  wi2wic -- Wiki To Wiki Converter
 *  Copyright (C) 2020 Stephane Carrez
 *  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
var Porion;
(function (Porion) {
    var BarGraph = /** @class */ (function () {
        function BarGraph(container, legend, labels, values) {
            var div = document.getElementById(container);
            var data = {
                labels: labels,
                datasets: [{
                        name: "Language",
                        type: "line",
                        values: values
                    }]
            };
            var chart = new Frappe.Chart(div, {
                animate: 1,
                data: data,
                type: 'percentage',
                height: 150,
                valuesOverPoints: 0,
                maxSlices: 7,
                lineOptions: {
                    regionFill: 0,
                    dotSize: 1,
                    hideDots: 1
                },
                axisOptions: {
                    yAxisMode: "tick"
                },
                colors: ['red', 'blue', 'green']
            });
        }
        return BarGraph;
    }());
    Porion.BarGraph = BarGraph;
    var TestChart = /** @class */ (function () {
        function TestChart(options, project) {
            this.graphContainer = document.createElement('div');
            this.project = "";
            this.container = document.getElementById(options.container);
            this.container.appendChild(this.graphContainer);
            this.project = project;
            this.getData(null);
        }
        TestChart.prototype.getData = function (event) {
            var _this = this;
            if (this.project) {
                var project = this.project;
                var xmlhttp_1 = new XMLHttpRequest();
                xmlhttp_1.onload = function (evt) {
                    if (xmlhttp_1.status == 200 && _this.container) {
                        _this.updateData(JSON.parse(xmlhttp_1.response));
                    }
                };
                xmlhttp_1.open("GET", "/porion/api/v1/projects/" + project + "/tests/builds");
                xmlhttp_1.send();
            }
        };
        TestChart.prototype.updateData = function (content) {
            var pass = new Array();
            var fail = new Array();
            var timeout = new Array();
            var duration = new Array();
            var labels = new Array();
            var first_build = 10000;
            var last_build = 0;
            for (var _i = 0, _a = content.tests; _i < _a.length; _i++) {
                var test = _a[_i];
                if (test.build_status == "BUILD_PASS") {
                    if (test.build_number < first_build) {
                        first_build = test.build_number;
                    }
                    if (test.build_number > last_build) {
                        last_build = test.build_number;
                    }
                    timeout.push(test.timeout_count);
                    fail.push(test.fail_count + test.timeout_count);
                    pass.push(test.pass_count + test.fail_count + test.timeout_count);
                    duration.push(test.test_duration / 1000);
                    labels.push(String(test.build_number));
                }
            }
            var data = {
                labels: labels,
                datasets: [{
                        name: "Fail",
                        type: "line",
                        values: fail
                    }, {
                        name: "Timeout",
                        type: "line",
                        values: timeout
                    }, {
                        name: "Pass",
                        type: "line",
                        values: pass
                    }]
            };
            var chart = new Frappe.Chart(this.container, {
                animate: 1,
                data: data,
                type: 'line',
                height: 250,
                valuesOverPoints: 0,
                lineOptions: {
                    regionFill: 0,
                    dotSize: 1,
                    hideDots: 1
                },
                axisOptions: {
                    yAxisMode: "tick",
                    xAxisMode: "tick"
                },
                tooltipOptions: {
                    formatTooltipX: function (value) {
                        return "Build " + value;
                    }
                },
                colors: ['red', 'blue', 'green']
            });
        };
        return TestChart;
    }());
    Porion.TestChart = TestChart;
    var CoverageChart = /** @class */ (function () {
        function CoverageChart(options, project) {
            this.graphContainer = document.createElement('div');
            this.legendContainer = document.createElement('div');
            this.tooltipContainer = document.createElement('div');
            this.project = "";
            this.container = document.getElementById(options.container);
            this.container.appendChild(this.graphContainer);
            this.container.appendChild(this.legendContainer);
            this.project = project;
            this.legendContainer.className = 'graph-legend';
            this.graphContainer.className = 'graph-view';
            this.tooltipContainer.className = 'graph-tooltip';
            document.body.appendChild(this.tooltipContainer);
            this.getData(null);
        }
        CoverageChart.prototype.getData = function (event) {
            var _this = this;
            if (this.project) {
                var project = this.project;
                var xmlhttp_2 = new XMLHttpRequest();
                xmlhttp_2.onload = function (evt) {
                    if (xmlhttp_2.status == 200 && _this.container) {
                        _this.updateData(JSON.parse(xmlhttp_2.response));
                    }
                };
                xmlhttp_2.open("GET", "/porion/api/v1/projects/" + project + "/coverage");
                xmlhttp_2.send();
            }
        };
        CoverageChart.prototype.updateData = function (content) {
            var lines = new Array();
            var functions = new Array();
            var labels = new Array();
            var first_build = 10000;
            var last_build = 0;
            labels.push("");
            lines.push(0);
            functions.push(0);
            for (var _i = 0, _a = content.metrics; _i < _a.length; _i++) {
                var build = _a[_i];
                if (build.build_status == "BUILD_PASS") {
                    if (build.build_number < first_build) {
                        first_build = build.build_number;
                    }
                    if (build.build_number > last_build) {
                        last_build = build.build_number;
                    }
                    lines.push(build.lines / 10.0);
                    functions.push(build.functions / 10.0);
                    labels.push(String(build.build_number));
                }
            }
            var data = {
                labels: labels,
                datasets: [{
                        name: "Functions",
                        type: "line",
                        values: functions
                    }, {
                        name: "Lines",
                        type: "line",
                        values: lines
                    }]
            };
            var chart = new Frappe.Chart(this.graphContainer, {
                animate: 1,
                data: data,
                type: 'line',
                height: 250,
                valuesOverPoints: 0,
                lineOptions: {
                    regionFill: 0,
                    dotSize: 1,
                    hideDots: 1
                },
                axisOptions: {
                    yAxisMode: "tick",
                    xAxisMode: "tick"
                },
                tooltipOptions: {
                    formatTooltipY: function (value) {
                        return String(value) + "%";
                    },
                    formatTooltipX: function (value) {
                        return "Build " + value;
                    }
                },
                colors: ['green', 'blue', 'red']
            });
        };
        return CoverageChart;
    }());
    Porion.CoverageChart = CoverageChart;
})(Porion || (Porion = {}));
