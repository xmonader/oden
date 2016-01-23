#!/bin/bash
prg=$0
command=$1

if [ -z $command ]; then
  echo "Usage: $prg (validate|save)"
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ODENC=$DIR/../dist/oden/bin/odenc

cd $DIR
tests=$(find src -name *.oden)

print_success() {
  echo -e "\033[1;32m$*\033[0m"
}

print_err() {
  echo -e "\033[1;4;31m$*\033[0m"
}

for test in $tests; do
  tmp_oden_path=$(mktemp -d -t oden)
  tmp_go_path=$(mktemp -d -t oden_out)
  tmp_src_file=$tmp_oden_path/$test

  mkdir -p $(dirname $tmp_src_file)

  cp $test $tmp_src_file
  oden_out=$($ODENC -p$tmp_oden_path -o$tmp_go_path 2>&1)
  oden_return=$?

  go_out=$(GOPATH=$tmp_go_path go run $(find $tmp_go_path -name *.go) 2>&1)
  go_return=$?

  if [ ! -f "$test.expected.txt" ]; then
    if [[ $command == "validate" ]]; then
      print_err "✗ $test"
      echo "Missing file $test.expected.txt!"
      echo "Run \"$prg save\" to generate such a file."
      echo ""
      continue
    fi
  fi

  if [[ $oden_return -ne 0 ]]; then
    print_err "✗ $test"
    echo "$oden_out"
    echo ""
  elif [[ $go_return -ne 0 ]]; then
    print_err "✗ $test"
    echo "$go_out"
    echo ""
  else
    expected_out=$(cat "$test.expected.txt")
    if [[ $command == "save" ]]; then
      print_success "✓ $test"
      echo -e "\033[35mSaving results.\033[0m"
      echo -e $go_out > "$test.expected.txt"
    elif [[ $command == "validate" ]]; then
      if [[ $go_out == $expected_out ]]; then
        print_success "✓ $test"
      else
        print_err "✗ $test"
        echo "'$go_out' ≠ '$expected_out'"
      fi
    fi
  fi

  rm -r $tmp_oden_path
  rm -r $tmp_go_path
done
