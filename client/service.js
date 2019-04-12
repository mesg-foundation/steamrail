const { execute, verify } = require('./process')

const contract = '0x77a9de37aB5F4E7e9C9074928ca4A95aBF8e381d'
const task = 'world'

execute(contract, task, async inputs => inputs.a + inputs.b)

verify(contract, task, async inputs => 42)
