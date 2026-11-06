extends GdUnitTestSuite


func test_framework_failure_probe() -> void:
	assert_bool("--probe-fail" in OS.get_cmdline_user_args()).is_false()
