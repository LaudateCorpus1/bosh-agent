// This file was generated by go generate; DO NOT EDIT

package precis

type property int

const (
	pValid property = 1 << iota
	contextO
	contextJ
	disallowed
	unassigned
	freePVal
	idDis
)