# Copyright Vadim Eisenberg 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Modifications Copyright Sean Antony 2018
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

UNAME = ${shell uname}

# set LIB_DIRECTORY according to your specific environment
# run swift build and see where the output LIB is created

DEPLOYMENT_TARGET = x86_64-apple-macosx10.11
SWIFT_COMPILER_OPTIONS = -Xswiftc "-target" -Xswiftc ${DEPLOYMENT_TARGET}
PLATFORM = x86_64-apple-macosx10.10
LIB_DIRECTORY = ./.build/${PLATFORM}/debug
TEST_RESOURCES_DIRECTORY = ${LIB_DIRECTORY}/SwiftGit2PackageTests.xctest/Contents/Resources

build:
	swift build ${SWIFT_COMPILER_OPTIONS}

copyTestResources:
	mkdir -p ${TEST_RESOURCES_DIRECTORY}
	cp SwiftGit2Tests/Fixtures/*.zip ${TEST_RESOURCES_DIRECTORY}

test: copyTestResources
	swift test ${SWIFT_COMPILER_OPTIONS}

clean:
	swift package clean

.PHONY: build copyTestResources test clean