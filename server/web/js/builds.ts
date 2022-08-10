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
    export interface LogLine {
        number : number,
        level  : string,
        content: string
    }
    export interface LogCounters {
    	trace: number,
	debug: number,
	info: number,
	warning: number,
	error: number,
	fatal: number,
	unkown: number,
	context: number
    }
    export interface LogsStep {
    	step: number,
	logs: LogLine[],
	counts: LogCounters
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
    export class BuildLog {
        readonly logContainer : HTMLDivElement = <HTMLDivElement>document.createElement('div');
        container : HTMLElement | null;
        showAll   : HTMLElement | null;
        showInfo  : HTMLElement | null;
        showWarn  : HTMLElement | null;
	countAll  : HTMLElement | null;
	countInfo : HTMLElement | null;
	countWarn : HTMLElement | null;
        build     : string = "";

        constructor(options : Options, build: string) {
            this.build = build;
            this.container = document.getElementById(options.container);
            this.container.appendChild(this.logContainer);
            this.showAll = document.getElementById(options.btnShowAll);
            this.showInfo = document.getElementById(options.btnShowInfo);
            this.showWarn = document.getElementById(options.btnShowWarning);
            this.countAll = document.getElementById(options.countAll);
            this.countInfo = document.getElementById(options.countInfo);
            this.countWarn = document.getElementById(options.countWarn);
            this.getBuildLogs(null);
            if (this.showAll) {
                this.showAll.addEventListener("click", (event: Event) => {
                    this.setMode(event, 'build-show-all');
                });
            }
            if (this.showInfo) {
                this.showInfo.addEventListener("click", (event: Event) => {
                    this.setMode(event, 'build-show-info');
                });
            }
            if (this.showWarn) {
                this.showWarn.addEventListener("click", (event: Event) => {
                    this.setMode(event, 'build-show-warning');
                });
            }
        }
        getBuildLogs(event : Event) {
            if (this.build) {
                const build : string = this.build;
                const xmlhttp : XMLHttpRequest = new XMLHttpRequest();
                
                xmlhttp.onload = evt => {
                    if (xmlhttp.status == 200 && this.container) {
                        this.updateResult(JSON.parse(xmlhttp.response));
                    }
                };
                xmlhttp.open("GET", "/porion/api/v1/builds/" + build + "/logs");
                xmlhttp.send();
            }
        }
        updateResult(content : LogsStep[]) {
	    var warnCount : number = 0;
	    var infoCount : number = 0;
	    var allCount : number = 0;
	    for (var step of content) {
	    	var stepWarn : number = step.counts.warning + step.counts.error + step.counts.fatal;
		var infoCount : number = step.counts.info + step.counts.unkown;
	        warnCount = warnCount + stepWarn;
		infoCount = infoCount + infoCount + stepWarn;
		allCount = allCount + infoCount + stepWarn + step.counts.debug + step.counts.debug + step.counts.context;

	    	let stepDiv = document.createElement("div");
		stepDiv.className = 'log-step'
            	for (var log of step.logs) {
                    let div = document.createElement("div");
                    let line = document.createElement("div");
                    let content = document.createElement("div");
                    div.className = 'log-line log-level-' + log.level;
                    line.className = 'log-line-number';
                    line.textContent = log.number.toString();
                    content.className = 'log-content';
                    content.textContent = log.content;
                    div.appendChild(line);
                    div.appendChild(content);
                    stepDiv.appendChild(div);
            	}
		this.logContainer.appendChild(stepDiv);
	    }
	    if (this.countAll) {
	       this.countAll.textContent = String(allCount);
	    }
	    if (this.countInfo) {
	       this.countInfo.textContent = String(infoCount);
	    }
	    if (this.countWarn) {
	       this.countWarn.textContent = String(warnCount);
	    }
        }
        setMode(event : Event, mode : string) {
            this.container.classList.remove('build-show-all', 'build-show-info', 'build-show-warning');
            this.container.classList.add(mode);
        }
    }
}

