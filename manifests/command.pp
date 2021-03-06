#based upon nrpe::command.pp by rodjek - https://gist.github.com/rodjek/1619400

define nagiosclient::command (
    $command,
    $file,
    $ensure='present'
    ) {

    # validate that the ensure value is valid
    case $ensure {
        # if the command is not supposed to be present, remove it
        absent: {
            augeas { "removing nrpe command ${name}":
                changes => "rm command[./${name}]",
                onlyif  => "match command[./${name}] size != 0",
                context => "/files/${file}"
            }
        }
        # if the command is supposed to be present ensure it exists and has the desired value
        present: {
            augeas { "create command ${name}":
                context => "/files/${file}",
                changes => "set command[last() + 1]/${name} \"${command}\"",
                onlyif  => "match command[./${name}] size == 0"
            }
            augeas { "set command ${name} to '${command}'":
                    context => "/files/${file}",
                    changes => "set command[./${name}]/${name} \"${command}\"",
                    onlyif  => "match command[./${name}='${command}'] size == 0",
                    require => Augeas["create command ${name}"];
            }
        }
        # any other value throw an error and stop
        default: {
            fail("Invalid ensure value passed to Nrpeclient::Command[${name}]")
        }
    }
}