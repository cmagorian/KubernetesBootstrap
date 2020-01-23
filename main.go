/*
Copyright © 2020 Christopher Magorian <chrismagorian@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package main

import (
	"KubernetesBootstrap/clientSession"
	"fmt"
)

func main() {
	//cmd.Execute()
	cs, err := clientSession.NewClientSession("root", "HugBug4401!.", "192.168.1.101")
	if err != nil {
		panic(err)
	}

	cs.SetCommands([]string{"cat /etc/hostname", "apt-get install -y kubectl"})

	res, err := cs.RunCommands()
	if err != nil {
		panic(err)
	}

	for _, r := range res {
		fmt.Println(r)
	}
}
