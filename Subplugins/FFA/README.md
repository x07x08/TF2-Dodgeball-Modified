<h1> Convars </h1>

<table>
	<tr>
		<th>Name</th>
		<th>Default value</th>
		<th>Description</th>
	</tr>
	<tr>
		<td><code>tf_dodgeball_ffa_bot</code></td>
		<td><code>1</code></td>
		<td>Disable FFA when a bot joins?</td>
	</tr>
	<tr>
		<td><code>tf_dodgeball_ffa_timeout</code></td>
		<td><code>150</code></td>
		<td>Vote timeout (in seconds)</td>
	</tr>
	<tr>
		<td><code>tf_dodgeball_ffa_duration</code></td>
		<td><code>20</code></td>
		<td>Vote duration (in seconds)</td>
	</tr>
	<tr>
		<td><code>tf_dodgeball_ffa_mode</code></td>
		<td><code>1</code></td>
		<td>
			How does changing FFA affect the rockets?<br>
			0 - No effect, wait for the next spawn<br>
			1 - Destroy all active rockets<br>
			2 - Immediately change the rockets to be neutral
		</td>
	</tr>
	<tr>
		<td><code>tf_dodgeball_ffa_stealing</code></td>
		<td><code>1</code></td>
		<td>Allow stealing in FFA mode?</td>
	</tr>
	<tr>
		<td><code>tf_dodgeball_ffa_disablecfg</code></td>
		<td><code>sourcemod/dodgeball_ffa_disable.cfg</code></td>
		<td>Config file to execute when disabling FFA mode</td>
	</tr>
	<tr>
		<td><code>tf_dodgeball_ffa_enablecfg</code></td>
		<td><code>sourcemod/dodgeball_ffa_enable.cfg</code></td>
		<td>Config file to execute when enabling FFA mode</td>
	</tr>
	<tr>
		<td><code>tf_dodgeball_ffa_teams</code></td>
		<td><code>1</code></td>
		<td>Automatically swap players when a team is empty in FFA mode?</td>
	</tr>
</table>

<h1> Commands </h1>

<table>
	<tr>
		<th>Name</th>
		<th>Description</th>
	</tr>
	<tr>
		<td><code>sm_ffa</code></td>
		<td>Forcefully toggle FFA</td>
	</tr>
	<tr>
		<td><code>sm_voteffa</code></td>
		<td>Start a vote to toggle FFA</td>
	</tr>
</table>
