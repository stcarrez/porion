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
namespace Porion {
   export class BarGraph {

      constructor(container: string, legend: string, labels: string[], values: number[]) {
         var div : HTMLElement | null = document.getElementById(container);
         const data : Frappe.ChartData = {
            labels: labels,
            datasets: [{
                 name: "Language",
                 type: "line",
                 values: values
              }]
           };
           const chart : Frappe.Chart = new Frappe.Chart(div, {
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
           })
        }
    }

    export interface BuildTestInfo {
       build_id: number,
       build_number: number,
       build_date: string,
       build_status: string,
       pass_count: number,
       fail_count: number,
       timeout_count : number,
       test_duration: number
    }
    export interface BuildTests {
       project_id: string,
       tests: BuildTestInfo[]
    }

    export interface BuildCoverageInfo {
       build_id: number,
       build_number: number,
       build_date: string,
       build_status: string,
       lines: number,
       functions: number
    }
    export interface BuildCoverage {
       project_id: string,
       metrics: BuildCoverageInfo[]
    }

    export interface Options {
        container: string,
        btnShowAll: string,
        btnShowInfo: string,
        btnShowWarning: string,
        countAll: string,
        countInfo: string,
        countWarn: string
    }
    export class TestChart {
        readonly graphContainer : HTMLDivElement = <HTMLDivElement>document.createElement('div');
        container  : HTMLElement | null;
        project    : string = "";

        constructor(options : Options, project: string) {
            this.container = document.getElementById(options.container);
            if (this.container) {
               this.container.appendChild(this.graphContainer);
            }
            this.project = project;
            this.getData(null)
        }
        getData(event : Event | null) {
            if (this.project) {
                const project : string = this.project;
                const xmlhttp : XMLHttpRequest = new XMLHttpRequest();
                
                xmlhttp.onload = evt => {
                    if (xmlhttp.status == 200 && this.container) {
                        this.updateData(JSON.parse(xmlhttp.response));
                    }
                };
                xmlhttp.open("GET", "/porion/api/v1/projects/" + project + "/tests/builds");
                xmlhttp.send();
            }
        }
        updateData(content : BuildTests) {
           var pass : number[] = new Array();
           var fail : number[] = new Array();
           var timeout : number[] = new Array();
           var duration : number[] = new Array();
           var labels : string[] = new Array();
           var first_build : number = 10000;
           var last_build : number = 0;
           for (var test of content.tests) {
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
           const data : Frappe.ChartData = {
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
           const chart : Frappe.Chart = new Frappe.Chart(this.container, {
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
                 formatTooltipX: (value : number) => {
                    return "Build " + value
                 }
              },
              colors: ['red', 'blue', 'green']
           })
        }
    }

    export class CoverageChart {
        readonly graphContainer : HTMLDivElement = <HTMLDivElement>document.createElement('div');
        readonly legendContainer : HTMLDivElement = <HTMLDivElement>document.createElement('div');
        readonly tooltipContainer : HTMLDivElement = <HTMLDivElement>document.createElement('div');
        container  : HTMLElement | null;
        project    : string = "";

        constructor(options : Options, project: string) {
            this.container = document.getElementById(options.container);
            
            this.container.appendChild(this.graphContainer);
            this.container.appendChild(this.legendContainer);
            this.project = project;
            this.legendContainer.className = 'graph-legend';
            this.graphContainer.className = 'graph-view';
            this.tooltipContainer.className = 'graph-tooltip';
            document.body.appendChild(this.tooltipContainer);
            this.getData(null)
        }
        getData(event : Event) {
            if (this.project) {
                const project : string = this.project;
                const xmlhttp : XMLHttpRequest = new XMLHttpRequest();
                
                xmlhttp.onload = evt => {
                    if (xmlhttp.status == 200 && this.container) {
                        this.updateData(JSON.parse(xmlhttp.response));
                    }
                };
                xmlhttp.open("GET", "/porion/api/v1/projects/" + project + "/coverage");
                xmlhttp.send();
            }
        }
        updateData(content : BuildCoverage) {
           var lines : number[] = new Array();
           var functions : number[] = new Array();
           var labels : string[] = new Array();
           var first_build : number = 10000;
           var last_build : number = 0;
           labels.push("");
           lines.push(0);
           functions.push(0);
           for (var build of content.metrics) {
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
           const data : Frappe.ChartData = {
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
           const chart : Frappe.Chart = new Frappe.Chart(this.graphContainer, {
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
                 formatTooltipY: (value : number) => {
                    return String(value) + "%"
                 },
                 formatTooltipX: (value : number) => {
                    return "Build " + value
                 }
              },
              colors: ['green', 'blue', 'red']
           })
        }
    }
}
