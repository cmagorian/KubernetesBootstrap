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
package clientSession

import (
	// built-ins
	"bytes"
	"fmt"
	"net"

	// third-party
	"golang.org/x/crypto/ssh"
)

type ClientSession struct {
	Commands []string
	Client   *ssh.Client
	Buffer   *bytes.Buffer
}

func NewClientSession(usr, pwd, addr string) (cs *ClientSession, err error) {
	cs = &ClientSession{}
	config := &ssh.ClientConfig{
		User: usr,
		Auth: []ssh.AuthMethod{
			ssh.Password(pwd),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	cs.Client, err = ssh.Dial("tcp", net.JoinHostPort(addr, "22"), config)
	return
}

func (cs *ClientSession) SetCommand(cmd string) {
	cs.Commands = append(cs.Commands, cmd)
}

func (cs *ClientSession) SetCommands(cmds []string) {
	cs.Commands = cmds
}

func (cs *ClientSession) RunCommands() (result []string, err error) {
	if len(cs.Commands) == 0 {
		err = fmt.Errorf("No commands to run \n")
		return
	}

	for _, cmd := range cs.Commands {
		session, err := cs.Client.NewSession()
		if err != nil {
			break
		}

		cs.Buffer = &bytes.Buffer{}
		session.Stdout = cs.Buffer

		err = session.Run(cmd)
		if err != nil {
			break
		}
		result = append(result, cs.Buffer.String())
		err = session.Close()
	}
	return
}
